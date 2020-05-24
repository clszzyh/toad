defmodule Hf.MixProject do
  use Mix.Project

  def project do
    [
      app: :hf,
      version: "VERSION" |> File.read!() |> String.trim(),
      elixir: "~> 1.7",
      description: "Spider manager platform.",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      releases: releases(),
      deps: deps()
    ]
  end

  defp releases do
    [
      hf: [
        include_executables_for: [:unix],
        include_erts: true,
        applications: [runtime_tools: :permanent],
        steps: [:assemble, &copy_extra_files/1]
      ]
    ]
  end

  defp copy_extra_files(release) do
    File.cp!(".iex.exs", Path.join(release.path, ".iex.exs"))
    release
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Hf.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, github: "phoenixframework/phoenix", override: true},
      {:phoenix_ecto, "~> 4.1"},
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_live_view, github: "phoenixframework/phoenix_live_view", override: true},
      {:phoenix_live_dashboard, github: "phoenixframework/phoenix_live_dashboard"},
      {:floki, ">= 0.0.0"},
      {:phoenix_html, "~> 2.14.1", override: true},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.2.0"},
      {:plug_cowboy, "~> 2.2"},

      ## add-on
      {:phoenix_pubsub, github: "phoenixframework/phoenix_pubsub", override: true},
      {:ecto, "~> 3.4.3", override: true},
      {:paginator, "0.6.0"},
      {:oban, github: "sorentwo/oban"},
      {:httpoison, "~> 1.5"},
      {:poolboy, "~> 1.5.2"},
      {:timex, "~> 3.0"},
      {:cachex, "~> 3.2"},
      {:envy, "~> 1.1.1"},
      {:surface, github: "msaraiva/surface"},
      {:mock, "~> 0.3.0", only: :test},
      {:ecto_enum, "~> 1.4"},
      {:basic_auth, "~> 2.2.3"},
      {:scrivener_ecto, "~> 2.0"},
      {:sizeable, "~> 1.0"},
      {:plug, "~> 1.10.0", override: true},
      {:credo, "~> 1.4.0", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.migrate": ["ecto.migrate", "ecto.dump"],
      "ecto.rollback": ["ecto.rollback", "ecto.dump"],
      seed: ["run priv/repo/seeds.exs"],
      unlock: ["deps.clean --unused", "deps.unlock --unused"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
