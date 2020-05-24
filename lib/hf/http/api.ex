defmodule Hf.Http.Api do
  @moduledoc false

  use Hf.Http.Common

  @attributes [
    request: true,
    result: true,
    response: true,
    pre_request: true,
    pre_result: true,
    pre_response: true,
    real_method: true,
    method: true,
    url: false,
    oban: true,
    tag: false,
    version: false,
    meta: false,
    aid: false,
    name: false
  ]

  defstruct url: nil,
            rid: nil,
            aid: nil,
            name: nil,
            meta: %{},
            method: :get,
            source: nil,
            params: %{},
            body: %{},
            headers: %{},
            options: %{},
            requests: [],
            results: [],
            responses: [],
            methods: [],
            extra: %{},
            state: :ok,
            result: nil,
            version: nil,
            input: %{},
            persist: %{},
            trace: [],
            req: nil,
            resp: nil

  defmacro __using__(_) do
    attributes_ast =
      for {name, acc} <- @attributes do
        quote(do: Module.register_attribute(__MODULE__, unquote(name), accumulate: unquote(acc)))
      end

    quote generated: true do
      use Hf.Http.Common

      unquote(attributes_ast)

      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    tags = env.module |> Module.get_attribute(:tag) || []

    methods_ast =
      env.module
      |> Module.get_attribute(:method)
      |> Enum.reverse()
      |> Enum.map(&Ast.method_ast/1)

    expand_ast = Enum.map(tags, &Ast.tag_ast/1)

    quote generated: true do
      alias unquote(__MODULE__)

      unquote(expand_ast)
      unquote(methods_ast)

      @meta %{
        requests:
          @request
          |> Kernel.++(@pre_request)
          |> Enum.reverse()
          |> Middleware.prepare_middlewares(:req),
        responses:
          @response
          |> Kernel.++(@pre_response)
          |> Enum.reverse()
          |> Middleware.prepare_middlewares(:resp),
        results:
          @result
          |> Kernel.++(@pre_result)
          |> Enum.reverse()
          |> Middleware.prepare_middlewares(:result),
        tags: unquote(tags |> Macro.escape()),
        methods: @real_method |> Enum.reverse(),
        oban: @oban |> Kernel.||([]) |> Macro.escape(),
        source: __MODULE__,
        version: @version |> Kernel.||(1),
        meta: @meta |> Kernel.||(%{}),
        aid: @aid,
        name: @name,
        url: @url |> Kernel.||("<%= input.url %>")
      }
      @struct struct(Api, @meta |> Map.to_list())

      def meta, do: @meta

      def a do
        case @meta do
          %{aid: id} when is_integer(id) -> Domain.one(A, %{by: [id: id]})
          _ -> nil
        end
      end

      def struct(input \\ %{}), do: %Api{@struct | input: input}
      def hook(%{}, %Api{}), do: {:ignored, nil}
      defoverridable hook: 2
    end
  end

  def defmiddlewares(kind, mids) when is_list(mids) do
    Enum.map(mids, fn x -> defmiddleware(kind, x) end)
  end

  def defmiddlewares(kind, mid) when is_atom(mid), do: defmiddleware(kind, {mid, []})

  def defmiddleware(kind, mid) when is_atom(mid), do: defmiddleware(kind, {mid, []})

  def defmiddleware(kind, {mid, opt}) when is_atom(mid) and not is_list(opt) do
    defmiddleware(kind, {mid, [{mid, opt}]})
  end

  @kind_map %{req: :request, resp: :response, result: :result}
  def defmiddleware(:pipe, {mid, opt}) do
    kind = Map.fetch!(@kind_map, Tool.name_to_module(mid).kind)
    defmiddleware(kind, {mid, opt})
  end

  def defmiddleware(:special, {mid, _}), do: raise("Not supported special: #{mid}")

  @allow_kinds [:request, :response, :result, :pre_request, :pre_response, :pre_result, :method]
  def defmiddleware(kind, {mid, opt})
      when is_atom(mid) and is_list(opt) and kind in @allow_kinds do
    quote location: :keep do
      Module.put_attribute(__MODULE__, unquote(kind), {unquote(mid), unquote(opt)})
    end
  end

  for a <- [:pipe | @allow_kinds] do
    defmacro unquote(a)(mids), do: defmiddlewares(unquote(a), mids)
    defmacro unquote(a)(mid, opt) when is_atom(mid), do: defmiddlewares(unquote(a), [{mid, opt}])
  end

  for x <- [:url, :tag, :version, :meta, :aid, :name] do
    defmacro unquote(x)(o) do
      quote location: :keep, bind_quoted: [o: o, x: unquote(x)] do
        Module.put_attribute(__MODULE__, x, o)
      end
    end
  end

  def prefix(%__MODULE__{source: module, rid: rid, input: %{attempt: attempt, job_id: job_id}}) do
    id =
      case rid do
        nil -> "    "
        id -> id |> to_string() |> String.pad_leading(4, "0")
      end

    [{module |> Tool.api_name(), attempt, {job_id, id}}]
  end

  @display_kinds %{req: :r1, send: :r2, resp: :r3, result: :r4}
  @display_states %{ok: "✓", failed: "✗", error: "e", fatal: "!", paused: "p", ignored: "i"}

  def suffix(a, kind \\ nil)

  def suffix(%__MODULE__{trace: [{_, {{_, kind, middleware}, {state, result}}} | _]} = a, nil) do
    suffix(a, {kind, middleware, state, result})
  end

  def suffix(%__MODULE__{}, {kind, middleware, state, result}) do
    [
      {:pad_leading, 12, Map.fetch!(@display_kinds, kind)},
      {:pad_trailing, 24, middleware},
      Map.fetch!(@display_states, state),
      {:slice, {45, 60}, result}
    ]
  end
end
