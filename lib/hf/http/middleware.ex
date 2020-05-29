defmodule Hf.Http.Middleware do
  @moduledoc false

  use Hf.Http.Common

  @middlewares %{
    {:req, :before} => [
      :input,
      hook: [stage: :retry],
      method: [],
      oauth2: [],
      params: [],
      body: [],
      mock: [],
      proxy: [],
      hook: [stage: :before],
      headers: [header_strategy: :default],
      options: [option_strategy: :default],
      user_agent: [random: true]
    ],
    {:req, :after} => [
      :build_request,
      :head,
      hook: [stage: :after],
      persist: [stage: :after]
    ],
    {:resp, :before} => [
      :do_request,
      :build_response,
      hook: [stage: :before],
      content_type: [],
      telemetry_exec: [],
      persist: [stage: :before],
      floki_parse: [],
      text_parse: [],
      json_parse: [],
      unzip: []
    ],
    {:resp, :after} => [
      hook: [stage: :after],
      persist: [stage: :after]
    ],
    {:result, :before} => [hook: [stage: :before]],
    {:result, :after} => [hook: [stage: :after], enqueue: [], persist: [stage: :after]]
  }

  def modules(kind \\ nil)

  def modules(nil) do
    [:req, :resp, :result, :special]
    |> Enum.reduce([], fn kind, result -> result ++ modules(kind) end)
  end

  def modules(kind) do
    Util.modules()
    |> Enum.filter(fn x ->
      x
      |> Module.split()
      |> List.starts_with?(["Hf", "Http", kind |> to_string |> Macro.camelize()])
    end)
  end

  def prepare_middlewares(lists, kind) when is_list(lists) do
    lists = lists |> Tool.list_to_keyword()
    before_middlewares = @middlewares |> Map.fetch!({kind, :before}) |> Tool.list_to_keyword()
    after_middlewares = @middlewares |> Map.fetch!({kind, :after}) |> Tool.list_to_keyword()

    {before_middlewares, lists} = Tool.optional_filter(before_middlewares, lists, lists)
    {after_middlewares, lists} = Tool.optional_filter(after_middlewares, lists, lists)

    before_middlewares ++ lists ++ after_middlewares
  end

  defmacro __using__(_) do
    quote generated: true do
      use Hf.Http.Common

      def kind,
        do:
          __MODULE__
          |> to_string()
          |> String.split(".")
          |> Enum.at(-2)
          |> String.downcase()
          |> String.to_atom()

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep, generated: true do
      def pipe(%Api{}, _), do: {:ignored, nil}
      defoverridable pipe: 2
    end
  end
end
