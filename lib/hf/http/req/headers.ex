defmodule Hf.Http.Req.Headers do
  use Hf.Http.Middleware

  @headers_map %{
    default: %{
      "Connection" => "keep-alive",
      "Accept" => "*/*",
      "Cache-Control" => "no-cache"
    },
    json: %{
      "Content-Type" => "application/json",
      "Connection" => "keep-alive",
      "Accept" => "Application/json; Charset=utf-8"
    },
    spider: %{
      "Accept" =>
        "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3",
      "User-Agent" =>
        "5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/77.0.3865.90 Safari/537.36"
    }
  }

  def pipe(%Api{headers: %{} = headers} = a, input) do
    {headers, result} = build_headers(a, input, headers)
    {:ok, result, %Api{a | headers: headers}}
  end

  defp build_headers(a, input, headers, result \\ [])

  defp build_headers(%Api{} = a, %{header_strategy: strategy} = input, %{} = headers, result)
       when strategy != :none do
    hd = Map.fetch!(@headers_map, strategy)

    build_headers(
      a,
      %{input | header_strategy: :none},
      Tool.merge_map(headers, hd) |> Enum.into(%{}, fn {k, v} -> {to_string(k), v} end),
      [{strategy, hd} | result]
    )
  end

  defp build_headers(%Api{} = a, %{headers: hd} = input, %{} = headers, result)
       when is_list(hd) do
    build_headers(a, %{input | headers: Map.new(hd)}, headers, result)
  end

  defp build_headers(%Api{} = a, %{headers: %{} = hd} = input, %{} = headers, result) do
    build_headers(
      a,
      %{input | headers: :none},
      Tool.merge_map(headers, hd),
      [{:manual, hd} | result]
    )
  end

  defp build_headers(_, _, headers, result), do: {headers, result}
end
