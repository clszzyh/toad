defmodule Hf.Http.Resp.ContentType do
  use Hf.Http.Middleware

  alias Plug.Conn

  def pipe(
        %Api{persist: %{} = persist, state: :ok, resp: %Resp{headers: %{"Content-Type" => type}}} =
          a,
        _
      ) do
    parsed_result = Conn.Utils.content_type(type)
    type = guess_content_type(type)
    {:ok, {type, parsed_result}, %Api{a | persist: persist |> Map.put(:content_type, type)}}
  end

  defp guess_content_type("text/html" <> _), do: :html
  defp guess_content_type("application/json" <> _), do: :json
  defp guess_content_type("image/jpeg" <> _), do: :image
  defp guess_content_type("text/plain" <> _), do: :text

  defp guess_content_type(type) do
    use(Hf.ReportError, "出现其他类型")
    :other
  end
end
