defmodule Hf.Http.Fetcher do
  @moduledoc false

  use Hf.Http.Common

  def meta(mod), do: Tool.api_cast(mod).meta

  def replay(%R{source: source, input: input}, new_input \\ nil) do
    final_input = new_input || input
    source |> rq(final_input)
  end

  def replay_enqueue(%R{source: source, input: input}, new_input \\ nil) do
    final_input = new_input || input
    source |> enqueue(final_input)
  end

  def mock(r, middleware, input \\ nil)

  def mock(%R{} = r, middleware, input) when is_atom(middleware) and not is_list(input) do
    mock(r, middleware, [{middleware, input}])
  end

  def mock(%R{} = r, middleware, input) when is_atom(middleware) and is_list(input) do
    %Api{trace: trace, requests: requests, responses: responses, results: results} =
      a = r |> load() |> Map.fetch!(:api)

    kind =
      trace
      |> Enum.find_value(fn {_, {{k, name}, _}} ->
        if name == middleware, do: k, else: nil
      end) || raise("!")

    options =
      Enum.find_value(requests ++ responses ++ results, fn {k, v} ->
        if k == middleware, do: v, else: nil
      end) || raise("?")

    a |> reduce_apply_middleware(middleware, options, kind, input)
  end

  def prepare(mod, input \\ %{}) do
    module = mod |> Tool.api_cast(input)

    input
    |> Tool.merge_input()
    |> module.struct()
    |> handle_request()
  end

  def rq(module, input \\ %{}) do
    module
    |> prepare(input)
    |> resume()
  end

  def load(id) when is_integer(id), do: R |> Domain.find(id) |> load()

  def load(%R{} = r) do
    a = r |> Persist.load() |> maybe_build_request()
    %R{r | api: a}
  end

  def resume!(id) do
    id |> load |> resume()
  end

  def maybe_build_request(%Api{req: nil} = a) do
    error([:resume, "retry handle request"])
    a |> handle_request()
  end

  def maybe_build_request(a), do: a

  def resume(%Api{rid: id} = a) do
    r = R |> Domain.find(id)
    resume(%R{r | api: a})
  end

  def resume(%R{id: id, state: :paused}), do: {:paused, id}

  def resume(%R{api: %Api{} = a}) do
    a
    |> Request.do_request()
    |> handle_response()
    |> handle_result()
    |> handle_return()
  end

  def enqueue(mod, input \\ %{}) do
    module = mod |> Tool.api_cast(input)

    %{module: module, input: Tool.merge_input(input)}
    |> RequestWorker.new([{:tags, [module]} | module.meta.oban])
    |> Oban.insert!()
  end

  def spawn(a, source, input \\ %{})

  def spawn(%Api{input: %{job_id: job_id}, rid: id}, module, %{} = input)
      when is_integer(job_id) and is_integer(id) and is_atom(module) do
    module |> enqueue(input |> Map.merge(%{parent_id: id}))
  end

  def spawn(_, _, _), do: {:ignored, nil}

  defp handle_request(%Api{state: :ok, requests: middlewares} = a) do
    reduce_middleware(middlewares, a, :req)
  end

  defp handle_request(%Api{} = a), do: a

  defp handle_response(%Api{state: :fatal} = a), do: a

  defp handle_response(%Api{responses: middlewares} = a) do
    reduce_middleware(middlewares, a, :resp)
  end

  defp handle_result(%Api{state: :fatal} = a), do: a

  defp handle_result(%Api{results: middlewares} = a) do
    reduce_middleware(middlewares, a, :result)
  end

  defp reduce_middleware(middlewares, %Api{} = a, kind) do
    Enum.reduce(middlewares, a, fn {middleware, options}, %Api{input: input} = acc ->
      acc
      |> reduce_apply_middleware(middleware, options, kind)
      |> handle_middleware(acc, middleware, kind, input)
    end)
    |> handle_middleware_final(kind)
  end

  defp reduce_apply_middleware(a, middleware, options, kind, new_input \\ nil)

  defp reduce_apply_middleware(%Api{input: input} = a, middleware, options, kind, new_input)
       when is_list(options) and is_atom(middleware) do
    input = new_input || input
    input = options |> Tool.merge_map_like(input) |> Map.put(:kind, kind)

    middleware
    |> Tool.name_to_module()
    |> apply_middleware(a, input, kind)
  end

  defp apply_middleware(_, %Api{state: :fatal, result: result}, %{}, _), do: {:fatal, result}

  defp apply_middleware(module, %Api{} = a, %{} = input, kind) do
    flag_name = "#{module}_#{kind}_disabled" |> String.to_atom()

    input
    |> Map.get(flag_name)
    |> if do
      :disabled
    else
      module.pipe(a, input)
    end
  rescue
    e ->
      {:fatal,
       use(Hf.ReportError, type: :apply_middleware, reason: e, stacktrace: __STACKTRACE__)}
  end

  defp handle_middleware_final(%Api{} = a, _), do: a

  defp parse_middleware_result(new_result, a, old_result \\ nil)

  ## TODO 需要更新 body 的都放到这里，方便通知 websocket
  defp parse_middleware_result({:req_body, body}, %Api{} = a, {code, result}),
    do: {code, result, %Api{a | body: body}}

  defp parse_middleware_result({:resp_body, {code, result}, body}, %Api{} = a, _) do
    parse_middleware_result({:resp_body, body}, a, {code, result})
  end

  defp parse_middleware_result(
         {:resp_body, body},
         %Api{resp: %Resp{} = resp} = a,
         {code, result}
       ),
       do: {code, result, %Api{a | resp: %Resp{resp | body: body}}}

  defp parse_middleware_result(%Api{} = a, %Api{}, {code, result}), do: {code, result, a}
  defp parse_middleware_result({code, result}, %Api{} = a, _), do: {code, result, a}
  defp parse_middleware_result({code, result, %Api{} = a}, _, _), do: {code, result, a}

  defp parse_middleware_result(code, %Api{} = a, _) when is_atom(code) and code not in [nil],
    do: {code, nil, a}

  defp handle_middleware(_, %Api{state: :fatal} = a, _, _, _), do: a

  defp handle_middleware(result, %Api{source: module} = a, middleware, kind, input) do
    {code, result, a} = parse_middleware_result(result, a)

    body =
      case a do
        %Api{resp: %Resp{body: body}} -> body
        _ -> nil
      end

    {code, result, a} =
      cond do
        module |> function_exported?(middleware, 1) ->
          module
          |> apply(middleware, [body])
          |> parse_middleware_result(a, {code, result})

        module |> function_exported?(middleware, 3) ->
          module
          |> apply(middleware, [a, input, {code, result}])
          |> parse_middleware_result(a, {code, result})

        true ->
          {code, result, a}
      end

    a |> trace(middleware, {code, result}, kind) |> build_middleware({code, result})
  end

  @ignored_states [:ignored, :disabled]

  defp build_middleware(%Api{} = a, {:fatal, result}),
    do: build_middleware_fill_api(a, {:fatal, result})

  defp build_middleware(%Api{state: state} = a, {code, result})
       when state in [:ok | @ignored_states] and code not in @ignored_states do
    build_middleware_fill_api(a, {code, result})
  end

  defp build_middleware(%Api{} = a, {_, _}), do: a

  defp build_middleware_fill_api(%Api{} = a, {code, result}) do
    %Api{a | state: code, result: result}
  end

  def trace(a, middleware, res \\ nil, kind \\ :send)

  def trace(%Api{trace: [{i, _} | _]} = a, middleware, res, kind) do
    trace_1(a, res, middleware, i + 1, kind)
  end

  def trace(%Api{trace: []} = a, middleware, res, kind) do
    trace_1(a, res, middleware, 0, kind)
  end

  defp trace_1(%Api{state: code, result: result} = a, nil, middleware, index, kind) do
    trace_2(a, {code, result}, middleware, index, kind)
  end

  defp trace_1(%Api{} = a, {code, result}, middleware, index, kind) do
    trace_2(a, {code, result}, middleware, index, kind)
  end

  defp trace_2(
         %Api{trace: trace, input: %{job_id: job_id, attempt: attempt}} = a,
         {code, result},
         middleware,
         index,
         kind
       ) do
    ary =
      [{:pad_leading, 17, index}] ++
        Api.prefix(a) ++ Api.suffix(a, {kind, middleware, code, result})

    level =
      case middleware do
        :do_request ->
          :warn

        _ ->
          case code do
            :ignored -> :debug
            :ok -> :info
            :failed -> :warn
            error when error in [:error, :fatal] -> :error
          end
      end

    apply(Hf.LocalLogger, level, [ary])

    obj = {index, {{attempt, kind, middleware}, {code, result}}}
    Hf.maybe_broadcast_api(job_id, {:trace, obj})

    %Api{a | trace: [obj | trace]}
  end

  def handle_return(
        %Api{state: state, result: result, req: %Req{url: _}, input: %{job_id: job_id}} = a
      ) do
    warn(Api.prefix(a) ++ Api.suffix(a), box: :before, prefix: "rq ")

    if job_id do
      {state, result, a}
    else
      {state, result}
    end
  end
end
