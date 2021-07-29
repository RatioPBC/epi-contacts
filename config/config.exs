# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

defmodule EpiContacts.Database do
  @moduledoc false

  @spec repo_opts(keyword()) :: keyword()
  def repo_opts(opts) do
    opts ++ local_opts()
  end

  defp local_opts do
    if socket_dir = System.get_env("PGDATA") do
      [socket_dir: socket_dir]
    else
      [username: "postgres", password: "postgres"]
    end
  end
end

config :epi_contacts,
  ecto_repos: [EpiContacts.Repo],
  secure_session_cookies: true,
  http_client: HTTPoison

config :epi_contacts, EpiContacts.Gettext,
  allowed_locales: ~w(en es),
  default_locale: "en",
  one_module_per_locale: true

config :epi_contacts, Oban,
  repo: EpiContacts.Repo,
  engine: Oban.Pro.Queue.SmartEngine,
  queues: [default: 10],
  plugins: [
    Oban.Plugins.Gossip,
    Oban.Pro.Plugins.BatchManager,
    Oban.Pro.Plugins.Lifeline,
    Oban.Web.Plugins.Stats
  ]

# Configures the endpoint
config :epi_contacts, EpiContactsWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: EpiContactsWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: EpiContacts.PubSub,
  live_view: [signing_salt: "gkSfxdfC"],
  strict_transport_security: "max-age=31536000"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :logger_json, :backend, metadata: :all

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :epi_contacts, EpiContacts, signer: EpiContacts.Signature, ttl: 10_000

config :epi_contacts, EpiContacts.PostContactWorker, commcare_verification_sleep: 20_000

config :fun_with_flags, :persistence,
  adapter: FunWithFlags.Store.Persistent.Ecto,
  repo: EpiContacts.Repo

config :fun_with_flags, :cache_bust_notifications,
  enabled: true,
  adapter: FunWithFlags.Notifications.PhoenixPubSub,
  client: EpiContacts.PubSub

config :epi_contacts,
  http_client: HTTPoison,
  commcare_client: EpiContacts.Commcare.Client,
  metrics_api: EpiContacts.Monitoring.Cloudwatch,
  analytics_client: EpiContacts.Monitoring.AsyncAnalyticsClient,
  posthog_client: Posthog.Client,
  analytics_reporter: EpiContacts.Monitoring.AnalyticsReporter,
  analytics_reporter_application_name:
    "ANALYTICS_REPORTER_APPLICATION_NAME" |> System.get_env("share_my_contacts") |> String.to_atom()

config :sentry,
  environment_name: Mix.env(),
  included_environments: [:prod]

# enable_source_code_context: true,
# root_source_code_paths: [File.cwd!()]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
