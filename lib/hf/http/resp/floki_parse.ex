defmodule Hf.Http.Resp.FlokiParse do
  use Hf.Http.Middleware

  def pipe(%Api{state: :ok, resp: %Resp{body: body}}, %{floki_parse: %{} = paths})
      when is_binary(body) do
    body
    |> Floki.parse_document()
    |> case do
      {:ok, doc} -> {:resp_body, {:ok, paths}, doc |> find(paths)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp find(binary, paths) when is_binary(binary),
    do: binary |> Floki.parse_document!() |> find(paths)

  defp find(body, path) when is_binary(path), do: Floki.find(body, path)

  defp find(body, %{} = paths) do
    paths
    |> Enum.into(%{}, fn {name, {path, cfg}} ->
      {name,
       body
       |> Floki.find(path)
       |> Enum.map(fn x -> x |> floki_sub_fetch(cfg) end)
       |> maybe_take_first()}
    end)
  end

  defp maybe_take_first([a | []]), do: a
  defp maybe_take_first(a), do: a

  defp floki_sub_fetch(doc, attr) when is_binary(attr) do
    doc |> Floki.attribute(attr) |> List.first()
  end

  defp floki_sub_fetch(doc, :text) do
    doc |> Floki.text()
  end

  defp floki_sub_fetch(doc, {path, :text}) when is_binary(path) do
    doc |> Floki.find(path) |> Floki.text()
  end
end
