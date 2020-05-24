defmodule Hf.Http.Resp.BuildResponse do
  use Hf.Http.Middleware

  def pipe(%Api{state: :ok, resp: %Resp{status_code: code, headers: headers} = resp} = a, _)
      when is_list(headers) do
    {:ok, code, %Api{a | resp: %Resp{resp | headers: Map.new(headers)}}}
  end
end
