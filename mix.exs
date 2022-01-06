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
      docs: docs(),
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
        summary: [threshold: 0]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {EpiContacts.Application, []},
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
      {:ex_doc, "~> 0.21", runtime: false},
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

  defp docs do
    [
      api_reference: false,
      main: "epi-contacts",
      assets: "guides/assets",
      extra_section: "GUIDES",
      extras: extras(),
      formatters: ["html"],
      source_url: "https://github.com/RatioPBC/epi-contacts",
      nest_modules_by_prefix: [],
      before_closing_body_tag: &before_closing_body_tag/1,
      before_closing_head_tag: &before_closing_head_tag/1,
      output: "docs",
      javascript_config_path: nil
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@8.13.6/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({ startOnLoad: false, theme: "default" });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          graphEl.classList.add("mermaid-container");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition, function (svgSource, bindListeners) {
            graphEl.innerHTML = svgSource;
            bindListeners && bindListeners(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }

        for (const d of document.getElementsByClassName("details-following-code")) {
          const codeBlock = d.nextSibling;
          const details = document.createElement("details");
          details.classList.add("with-code");
          const summary = document.createElement("summary");
          const summaryText = document.createTextNode(d.dataset.summary);
          summary.appendChild(summaryText);
          details.appendChild(summary);
          details.appendChild(codeBlock);
          d.appendChild(details);
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""

  defp before_closing_head_tag(:html) do
    """
    <style>
      #content.content-inner {
        max-width: 1282px;
      }
      .mermaid-container {
        background-color: white;
      }

      .details-following-code ~ pre {
        display: none;
      }

      .details-following-code details.with-code pre {
        display: block;
      }

      details > summary {
        cursor: pointer;
      }
    </style>
    """
  end

  defp before_closing_head_tag(_), do: ""

  defp extras do
    [
      "README.md": [filename: "epi-contacts", title: "Epi Contacts"],
      "guides/overview.md": [],
      LICENSE: []
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
      docs: ["docs", &copy_images/1],
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", &compile_assets/1, "test"]
    ]
  end

  defp compile_assets(_) do
    Mix.shell().cmd("npm run build --prefix assets")
  end

  defp copy_images(_) do
    File.cp_r("guides/assets", "docs/assets")
  end
end
