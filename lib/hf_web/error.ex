defmodule HfWeb.Error do
  alias Hf.Util
  alias HfWeb.Helper

  def handle(conn, %{reason: %Ecto.NoResultsError{message: message}}) do
    conn |> Helper.api_ok(code: 30_000, message: "找不到对象", result: message)
  end

  def handle(conn, %{reason: %Phoenix.Router.NoRouteError{message: message}}) do
    conn |> Helper.api_ok(code: 20_004, message: "找不到路由", result: message)
  end

  def handle(conn, %{reason: %RuntimeError{message: message}, stack: stack}) do
    conn
    |> Helper.api_ok(
      code: 20_000,
      message: message |> inspect,
      result: stack |> Util.format_stack()
    )
  end

  def handle(conn, %{kind: kind, reason: reason, stack: stack}) do
    conn
    |> Helper.api_ok(
      message: inspect(reason),
      code: 20_000,
      result: %{
        kind: kind,
        class: reason.__struct__,
        stack: stack |> Util.format_stack()
      }
    )
  end
end
