defmodule EpiContacts.Application do
  @moduledoc false
  use Application
  require Cachex.Spec
  alias EpiContacts.Monitoring.AnalyticsReporter

  defmodule SentryConfig do
    @moduledoc false
    def ca_bundle do
      Application.get_env(:epi_contacts, :sentry_ca_bundle)
    end

    def hackney_opts(bundle \\ ca_bundle())
    def hackney_opts(nil), do: []
    def hackney_opts(cert) when is_binary(cert), do: [ssl_options: [cacertfile: cert]]
  end

  def start(_type, _args) do
    configure_sentry()
    configure_metrics()
    configure_posthog()

    children = [
      EpiContacts.Repo,
      EpiContactsWeb.Telemetry,
      {Phoenix.PubSub, name: EpiContacts.PubSub},
      EpiContactsWeb.Endpoint,
      {Oban, oban_config()}
    ]

    EpiContacts.ObanErrorReporter.setup()

    # find a way to mock our AnalyticsReporter before EpiContacts.Application.start() is invoked
    if Application.get_env(:epi_contacts, :environment_name) != :test do
      AnalyticsReporter.setup()
    end

    opts = [strategy: :one_for_one, name: EpiContacts.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    EpiContactsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def merge_env(app, key, new_values) when is_list(new_values) do
    merged =
      app
      |> Application.get_env(key)
      |> Config.Reader.merge(new_values)

    Application.put_env(app, key, merged)
  end

  defp oban_config do
    opts = Application.get_env(:epi_contacts, Oban)

    # Prevent running queues or scheduling jobs from an iex console, i.e. when starting app with `iex -S mix`
    if Code.ensure_loaded?(IEx) and IEx.started?() do
      opts
      |> Keyword.put(:crontab, false)
      |> Keyword.put(:queues, false)
    else
      opts
    end
  end

  defp configure_metrics do
    Application.get_env(:epi_contacts, :environment_name, Application.get_env(:epi_contacts, :release_level))
    |> String.to_existing_atom()
    |> (&Application.put_env(:epi_contacts, :environment_name, &1)).()
  end

  defp configure_sentry do
    dsn = Application.get_env(:epi_contacts, :sentry_dsn)
    environment_name = :epi_contacts |> Application.get_env(:release_level) |> String.to_existing_atom()
    hackney_opts = SentryConfig.hackney_opts()

    Application.put_env(:sentry, :dsn, dsn)
    Application.put_env(:sentry, :environment_name, environment_name)
    Application.put_env(:sentry, :included_environments, [:dev, :staging, :prod])
    Application.put_env(:sentry, :hackney_opts, hackney_opts)
  end

  defp configure_posthog do
    posthog_api_url = Application.get_env(:epi_contacts, :posthog_api_url)
    posthog_api_key = Application.get_env(:epi_contacts, :posthog_api_key)
    Application.put_env(:posthog, :api_url, posthog_api_url)
    Application.put_env(:posthog, :api_key, posthog_api_key)
  end
end
