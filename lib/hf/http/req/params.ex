defmodule Hf.Http.Req.Params do
  use Hf.Http.Middleware

  def pipe(%Api{params: %{} = old_params} = a, %{params: params}) do
    {:ok, params, %Api{a | params: old_params |> Map.merge(params)}}
  end
end
