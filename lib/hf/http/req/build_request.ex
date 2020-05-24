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
    {:ok, url |> EEx.eval_string(Map.to_list(a)) |> URI.parse() |> URI.to_string()}
  rescue
    e ->
      {:fatal, use(Hf.ReportError, type: :build_url, reason: e, stacktrace: __STACKTRACE__)}
  end

  defp build_url(_), do: {:error, :url_not_match}

  defp build_params(%Api{params: %{} = params}), do: {:ok, params}
  defp build_params(_), do: {:error, :params_not_match}

  defp build_method(%Api{method: method}) when is_atom(method), do: {:ok, method}
  defp build_method(_), do: {:error, :method_not_match}

  defp build_body(%Api{body: %{} = body}), do: Jason.encode(body)
  defp build_body(%Api{body: body}) when is_binary(body), do: {:ok, body}
  defp build_body(_), do: {:error, :body_not_match}

  defp build_headers(%Api{headers: %{} = headers}),
    do: {:ok, Enum.map(headers, fn {k, v} -> {to_string(k), v} end)}

  defp build_headers(%Api{headers: headers}) when is_list(headers), do: {:ok, headers}
  defp build_headers(_), do: {:error, :headers_not_match}

  defp build_options(%Api{options: %{} = options}), do: {:ok, Tool.map_to_list(options)}
  defp build_options(%Api{options: options}) when is_list(options), do: {:ok, options}
  defp build_options(_), do: {:error, :options_not_match}
end
