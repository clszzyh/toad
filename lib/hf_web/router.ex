defmodule HfWeb.Router do
  use HfWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HfWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :admin_only do
    plug BasicAuth, use_config: {:hf, :basic_auth}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HfWeb do
    pipe_through :browser

    live "/", ApiIndexLive, :index
    live "/page", PageLive, :index
  end

  scope "/" do
    pipe_through [:browser, :admin_only]
    live_dashboard "/dashboard", metrics: HfWeb.Telemetry
  end

  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack} = error) do
    HfWeb.Error.handle(conn, error)
  end
end
