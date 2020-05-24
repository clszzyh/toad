defmodule Hf.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Hf.Http

  def start(_type, _args) do
    Envy.auto_load()
    Envy.reload_config()

    children = [
      # Start the Ecto repository
      Hf.Repo,
      Http.Registry,
      :hackney_pool.child_spec(:default_pool, timeout: 10_000, max_connections: 100),
      # Start the Telemetry supervisor
      HfWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Hf.PubSub},
      # Start the Endpoint (http/https)
      HfWeb.Endpoint,
      {Oban, oban_config()}
      # Start a worker by calling: Hf.Worker.start_link(arg)
      # {Hf.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hf.Supervisor]
    result = Supervisor.start_link(children, opts)

    if Code.ensure_loaded?(IEx) and IEx.started?() do
      :ok = Http.Config.load()
      Hf.hide_debug!(:all)
    end

    result
  end

  defp oban_config do
    opts = Application.get_env(:hf, Oban)

    # Prevent running queues or scheduling jobs from an iex console.
    if Code.ensure_loaded?(IEx) and IEx.started?() do
      opts
      # |> Keyword.put(:crontab, true)
      # |> Keyword.put(:queues, true)
    else
      opts
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    HfWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
