defmodule Hf.Http.Resp.TelemetryExec do
  use Hf.Http.Middleware

  def pipe(%Api{url: url, state: state, extra: %{duration: duration}}, _) do
    :ok =
      :telemetry.execute([:hf, :http, :request], %{duration: duration}, %{
        url: url,
        state: state
      })

    :ok
  end
end
