defmodule EpiContacts.MixProject do
  use Mix.Project

  def project do
    [
      app: :epi_contacts,
      version: "0.1.0",
      dialyzer: dialyzer(),
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        epi_contacts: [
          include_executables_for: [:unix],
          applications: [
            runtime_tools: :permanent
          ]
        ]
      ],
      xref: [exclude: IEx],
      test_coverage: [
        summary: [ threshold: 0 ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {EpiContacts.Application, []},
      extra_applications: [:logger, :runtime_tools]
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
      {:bcrypt_elixir, "~> 2.0"},
      {:briefly, "~> 0.1"},
      {:bypass, "~> 2.1", only: :test},
      {:cachex, "~> 3.2"},
      {:commcare_api, "~> 0.2"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:ecto, "~> 3.4"},
      {:ecto_sql, "~> 3.4"},
      {:elixir_xml_to_map, "~> 2.0"},
      {:euclid, "~> 0.2"},
      {:ex_aws, "~> 2.0"},
      {:ex_aws_cloudwatch, "~> 2.0"},
      {:floki, ">= 0.0.0"},
      {:fun_with_flags, "~> 1.5"},
      {:fun_with_flags_ui, "~> 0.7"},
      {:gettext, "~> 0.18"},
      {:hammox, "~> 0.5"},
      {:httpoison, "~> 1.6"},
      {:jason, "~> 1.0"},
      {:kcl, "~> 1.3"},
      {:logger_json, "~> 4.2"},
      {:mix_audit, "~> 1.0", only: [:dev, :test], runtime: false},
      {:oban, "~> 2.10"},
      {:oban_pro, "~> 0.9", organization: "oban"},
      {:oban_web, "~> 2.8", organization: "oban"},
      {:paseto, "~> 1.3"},
      {:phoenix, "~> 1.6"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 3.1"},
      {:phoenix_integration, "~> 0.9", only: :test},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, "~> 0.15"},
      {:posthog, "~> 0.1"},
      {:stream_data, "~> 0.5", only: [:dev, :test]},
      {:sentry, "~> 7.0"},
      {:sobelow, "~> 0.8", only: :dev},
      {:telemetry_poller, "~> 0.4"},
      {:timex, "~> 3.5"},
      {:uuid, "~> 1.1"},
      {:vapor, "~> 0.8"},
      {:wallaby, "~> 0.24.0", runtime: false, only: :test},
      {:xml_builder, "~> 2.1"},
      {:nimble_totp, "~> 0.1"}
    ]
  end

  defp dialyzer do
    [
      plt_add_apps: [:iex],
      plt_add_deps: :app_tree,
      plt_file: {:no_warn, "priv/plts/dialyzer.plt"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", &compile_assets/1, "test"]
    ]
  end

  defp compile_assets(_) do
    Mix.shell().cmd("npm run build --prefix assets")
  end
end
