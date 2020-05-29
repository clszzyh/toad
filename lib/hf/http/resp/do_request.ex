defmodule Hf.Http.Resp.DoRequest do
  use Hf.Http.Middleware

  def pipe(%Api{state: :ok, resp: nil, req: %Req{} = req} = a, _) do
    req
    |> HTTPoison.request()
    |> case do
      {:ok, %Resp{status_code: status_code} = resp} ->
        %Api{a | resp: resp, result: status_code}

      {:error, %Error{reason: reason}} ->
        %Api{a | state: :failed, result: reason}
    end
  end
end
