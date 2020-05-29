defmodule Hf.Http.Req.BuildRequest do
  use Hf.Http.Middleware

  def pipe(%Api{state: :ok} = a, _) do
    with {:ok, url} <- build_url(a),
         {:ok, method} <- build_method(a),
         {:ok, params} <- build_params(a),
         {:ok, body} <- build_body(a),
         {:ok, headers} <- build_headers(a),
         {:ok, options} <- build_options(a) do
      {:ok, nil,
       %Api{
         a
         | req: %Req{
             url: url,
             method: method,
             headers: headers,
             body: body,
             options: options,
             params: params
           }
       }}
    else
      {:error, reason} -> {:fatal, reason}
      {:fatal, reason} -> {:fatal, reason}
    end
  rescue
    e ->
      {:fatal, use(Hf.ReportError, type: :build_request, reason: e, stacktrace: __STACKTRACE__)}
  end

  defp build_url(%Api{url: url} = a) when is_binary(url) do
    eex = "<%= context[:url_prefix] %>" <> url <> "<%= input[:url_suffix] %>"

    eex
    |> handle_eval(a)
    |> case do
      {:ok, s} -> {:ok, s |> URI.parse() |> URI.to_string()}
      other -> other
    end
  end

  defp build_url(_), do: {:error, :url_not_match}

  defp build_params(%Api{params: %{} = params} = a) do
    params
    |> enum_eval(a)
    |> case do
      {:ok, a} -> {:ok, Enum.into(a, %{})}
      o -> o
    end
  end

  defp build_params(_), do: {:error, :params_not_match}

  defp build_method(%Api{method: method}) when is_atom(method), do: {:ok, method}
  defp build_method(_), do: {:error, :method_not_match}

  defp build_body(%Api{body: %{} = body} = a) do
    body
    |> Jason.encode()
    |> case do
      {:ok, body} -> build_body(%Api{a | body: body})
      o -> o
    end
  end

  defp build_body(%Api{body: body} = a) when is_binary(body), do: handle_eval(body, a)
  defp build_body(_), do: {:error, :body_not_match}

  defp build_headers(%Api{headers: %{} = headers} = a),
    do: build_headers(%Api{a | headers: Enum.map(headers, fn {k, v} -> {to_string(k), v} end)})

  defp build_headers(%Api{headers: headers} = a) when is_list(headers) do
    headers |> enum_eval(a)
  end

  defp build_headers(_), do: {:error, :headers_not_match}
  defp build_options(%Api{options: %{} = options}), do: {:ok, Tool.map_to_list(options)}
  defp build_options(%Api{options: options}) when is_list(options), do: {:ok, options}
  defp build_options(_), do: {:error, :options_not_match}

  defp enum_eval(o, %Api{} = a) when is_list(o) or is_map(o) do
    o |> Enum.reduce({:ok, []}, fn x, result -> reduce_eval(x, a, result) end)
  end

  defp reduce_eval({k, v}, %Api{} = a, {:ok, ary}) when is_list(ary) do
    with {:ok, k} <- handle_eval(k, a),
         {:ok, v} <- handle_eval(v, a) do
      {:ok, ary ++ [{k, v}]}
    else
      o -> o
    end
  end

  defp handle_eval(s, %Api{} = a) when is_binary(s) do
    {:ok, s |> EEx.eval_string(Map.to_list(a))}
  rescue
    e -> {:fatal, use(Hf.ReportError, type: :handle_eval, reason: e, stacktrace: __STACKTRACE__)}
  end

  defp handle_eval(s, _), do: {:ok, s}
end
