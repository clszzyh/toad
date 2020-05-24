defmodule Hf.Http.Special.Hook do
  use Hf.Http.Middleware

  def pipe(%Api{source: module} = a, %{} = input) do
    module.hook(input, a)
  end
end
