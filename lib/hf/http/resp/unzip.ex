defmodule Hf.Http.Resp.Unzip do
  use Hf.Http.Middleware

  alias Plug.Conn

  # https://bernheisel.com/blog/httpoison-decompression/

  def pipe(%Api{state: :ok, resp: %Resp{body: _, headers: %{}} = resp} = a, _) do
    {%Resp{body: body}, result} =
      {resp, []}
      |> decompress_response()
      |> reencode_response_to_utf8()

    {:ok, result, %Api{a | resp: %Resp{resp | body: body}}}
  end

  defp decompress_response(
         {%Resp{body: body, headers: %{"Content-Encoding" => encoding}} = resp, result}
       ) do
    {body, resu} = decompress_body(encoding, body)
    {%Resp{resp | body: body}, [{encoding, resu} | result]}
  end

  defp decompress_response(a), do: a

  defp reencode_response_to_utf8(
         {%Resp{headers: %{"Content-Type" => type}, body: body} = resp, result}
       )
       when not is_nil(type) do
    {body, resu} =
      case Conn.Utils.content_type(type) do
        {:ok, _, _, %{"charset" => charset}} ->
          cond do
            charset =~ ~r/utf-?8/ -> :utf8
            charset =~ ~r/iso-?8859-?1/ -> :latin1
            true -> charset
          end

        _ ->
          nil
      end
      |> reencode_body(body)

    {%Resp{resp | body: body}, [{type, resu} | result]}
  end

  defp reencode_response_to_utf8(a), do: a

  defp reencode_body(nil, body), do: {body, nil}
  defp reencode_body(:utf8, body), do: {body, nil}

  defp reencode_body(:latin1, body) do
    case :unicode.characters_to_binary(body, :latin1, :utf8) do
      {:error, binary, rest} ->
        error("Failed to re-encode text. BODY: #{inspect(binary)} REST: #{inspect(rest)}")
        {body, :failed}

      {:incomplete, reencoded_text, rest} ->
        error("Failed to re-encode entire text. Dropping characters: #{inspect(rest)}")
        {reencoded_text, :incomplete}

      reencoded_text ->
        {reencoded_text, :ok}
    end
  end

  defp reencode_body(_, body), do: {body, :other}

  defp decompress_body("deflate", body), do: {:zlib.unzip(body), :ok}

  defp decompress_body(encoding, <<31, 139, 8, _::binary>> = body)
       when encoding in ["gzip", "x-gzip"],
       do: {:zlib.gunzip(body), :ok}

  defp decompress_body(_, body), do: {body, :other}
end
