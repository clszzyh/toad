defmodule Hf.Http.Resp.TextParse do
  use Hf.Http.Middleware

  def pipe(%Api{state: :ok, resp: %Resp{body: body} = resp} = a, %{
        text_parse: {:string_split, char}
      })
      when is_binary(body) do
    result = body |> String.split(to_string(char)) |> Enum.reject(&match?("", &1))
    {:ok, Enum.count(result), %Api{a | resp: %Resp{resp | body: result}}}
  end
end
