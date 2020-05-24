defmodule Hf.Http.Req.Method do
  use Hf.Http.Middleware

  def pipe(%Api{} = a, %{method: method}) when is_atom(method) do
    {:ok, method, %Api{a | method: method}}
  end
end
