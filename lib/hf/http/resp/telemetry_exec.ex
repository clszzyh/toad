defmodule Hf.Http.Resp.TelemetryExec do
  use Hf.Http.Middleware

  def pipe(%Api{url: url, state: state} = a, _) do
    duration = Api.timeout(a)

    :ok =
      :telemetry.execute([:hf, :http, :request], %{duration: duration}, %{
        url: url,
        state: state
      })

    {:ok, duration}
  end
end
