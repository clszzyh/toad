# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :tzdata, :autoupdate, :disabled

config :hf, ecto_repos: [Hf.Repo]

config :hackney, mod_metrics: Hf.Metrics

# Configures the endpoint
config :hf, HfWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "rT32EUFv+n/Pn1rZoxL8Pe486q2qwpMuX4Hfw0mryccyl+Fpqlxu3tV9rln6RPW1",
  render_errors: [view: HfWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Hf.PubSub,
  live_view: [signing_salt: "MLWqr4V6"]

config :hf, Oban,
  repo: Hf.Repo,
  # verbose: :debug,
  crontab: [{"*/55 * * * *", Hf.Workers.HelloWorld}],
  poll_interval: 2_500,
  queues: [default: 10, events: 50, proxy: 30]

# Configures Elixir's Logger
config :logger, :console,
  format: {Hf.LocalLogger, :format},
  colors: [enabled: true, info: :blue]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :hf,
  basic_auth: [
    username: "admin",
    password: "minda"
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
