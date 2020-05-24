defmodule HfWeb.Helper do
  @moduledoc false
  use HfWeb, :controller
  alias Hf.Util

  @version Mix.Project.config()[:version] <> "_" <> (System.get_env("GIT_REV") || "unknown")

  def api_ok(conn, [_ | _] = data) do
    api_ok(conn, Map.new(data))
  end

  def api_ok(%Conn{assigns: %{start_time: start_time}} = conn, %{} = data) do
    now = Timex.now()
    cost = (now |> Timex.diff(start_time, :milliseconds)) * 0.001

    render_ok(conn, %{
      result: data,
      version: @version,
      now: Util.now(),
      cost: cost |> Float.round(3)
    })
  end

  def api_ok(conn, data) do
    render_ok(conn, data)
  end

  def html_ok(conn, data) do
    conn |> put_status(:ok) |> html(data)
  end

  defp render_ok(%Conn{method: method, remote_ip: ip, request_path: request_path} = conn, data) do
    info([method, request_path, ip, data])

    conn
    |> put_status(:ok)
    |> put_view(HfWeb.FinalView)
    |> render("result.json", data: data)
  end
end
