defmodule Hf.Http.Req.Head do
  use Hf.Http.Middleware

  def pipe(%Api{req: %Req{} = req}, %{head: true}) do
    req
    |> Map.put(:method, :head)
    |> HTTPoison.request()
    |> case do
      {:ok, %Resp{headers: headers}} ->
        headers = Map.new(headers)
        debug([:head_headers, headers])
        headers |> maybe_info_content_length()
        {:ok, headers}

      {:error, %Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp maybe_info_content_length(%{"Content-Length" => length}) do
    info(["请求大小", Sizeable.filesize(length)])
  end

  defp maybe_info_content_length(_), do: nil
end
