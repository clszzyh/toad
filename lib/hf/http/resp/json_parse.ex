defmodule Hf.Http.Resp.JsonParse do
  use Hf.Http.Middleware

  def pipe(%Api{state: :ok, resp: %Resp{body: body} = resp} = a, %{json_parse: true})
      when is_binary(body) do
    body
    |> Jason.decode()
    |> case do
      {:error, _} -> {:error, :json_decode_error}
      {:ok, map} -> {:ok, Enum.count(map), %Api{a | resp: %Resp{resp | body: map}}}
    end
  end
end
