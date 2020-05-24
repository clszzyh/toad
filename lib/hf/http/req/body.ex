defmodule Hf.Http.Req.Body do
  use Hf.Http.Middleware

  def pipe(%Api{} = a, %{body: body}) do
    {:ok, body, %Api{a | body: body}}
  end
end
