defmodule Hf.Http.Ast do
  use Hf.Http.Common

  @blank_ast (quote do
              end)

  require Api

  @macros [
    version: :version,
    url: :url,
    meta: :meta,
    tags: :tag,
    pipes: :pipe,
    id: :aid,
    name: :name,
    methods: :method,
    tests: :test,
    context: :context,
    input: :input
  ]

  for {k, n} <- @macros do
    def config_ast({unquote(k), v}) do
      {{:., [], [{:__aliases__, [alias: Api], [:Api]}, unquote(n)]}, [], [Macro.escape(v)]}
    end
  end

  def config_ast({_, _}), do: @blank_ast

  def method_ast({mid, opt}) when is_atom(mid) do
    args_ast = opt[:args]
    when_ast = opt[:when]
    body_ast = opt[:body]

    display =
      [:args, :when, :body]
      |> Enum.map(fn k -> {k, A.display_methods({k, opt[k]})} end)
      |> Enum.reject(&match?({_, v} when v in ["", nil], &1))

    common =
      quote(do: Module.put_attribute(__MODULE__, :real_method, {unquote(mid), unquote(display)}))

    if when_ast do
      quote do
        def unquote(mid)(unquote_splicing(args_ast)) when unquote(when_ast), do: unquote(body_ast)
        unquote(common)
      end
    else
      quote do
        def unquote(mid)(unquote_splicing(args_ast)), do: unquote(body_ast)
        unquote(common)
      end
    end
  end

  def tag_ast(:follow_redirect) do
    quote(do: pre_request(options: %{follow_redirect: true}))
  end

  def tag_ast(:head) do
    quote(do: pre_request(head: true))
  end

  def tag_ast(:paused) do
    quote(do: pre_request(input: [initial_state: :paused]))
  end

  def tag_ast(:restful_i_as_url_suffix) do
    ast = [args: quote(do: [_, %{i: i}, _]), body: quote(do: {:input, {:url_suffix, i}})]

    quote do
      unquote(method_ast({:body, ast}))
    end
  end

  def tag_ast({:mock_retry, kind}) do
    quote do
      unquote(method_ast({:hook, mock_retry_method_ast(kind)}))
    end
  end

  def tag_ast({:retry, kind}) do
    quote do
      @oban {:max_attempts, 5}
      unquote(method_ast({:hook, retry_method_ast(kind)}))
    end
  end

  def tag_ast(tag) do
    error([:tag_not_match, tag])
    @blank_ast
  end

  defp mock_retry_method_ast(:resp) do
    [
      args: quote(do: [%{kind: :resp, stage: :after, attempt: attempt}, _]),
      when: quote(do: attempt < 3),
      body: quote(do: {:failed, attempt})
    ]
  end

  defp retry_method_ast(:debug) do
    [
      args:
        quote(
          do: [
            %{kind: :req, stage: :retry, attempt: attempt},
            %Api{}
          ]
        ),
      body:
        quote(
          do:
            (
              debug([:retry_hook, attempt])
              {:ok, attempt}
            )
        )
    ]
  end

  defp retry_method_ast(:local_proxy_http) do
    [
      args:
        quote(
          do: [
            %{kind: :req, stage: :retry, attempt: attempt},
            %Api{input: %{} = input} = a
          ]
        ),
      when: quote(do: attempt > 1),
      body: quote(do: {:ok, attempt, %Api{a | input: Map.put(input, :proxy, :local_http)}})
    ]
  end
end
