import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

config :epi_contacts,
       EpiContacts.Repo,
       [
         database: "epi_contacts_test#{System.get_env("MIX_TEST_PARTITION")}",
         pool: Ecto.Adapters.SQL.Sandbox,
         show_sensitive_data_on_connection_error: true
       ]
       |> EpiContacts.Database.repo_opts()

# Print only warnings and errors during test
config :logger, level: :warn

config :wallaby,
  driver: Wallaby.Experimental.Chrome,
  chrome: [headless: true],
  hackney_options: [timeout: :infinity, recv_timeout: :infinity],
  screenshot_on_failure: true,
  js_errors: true

config :epi_contacts, EpiContactsWeb.Endpoint, server: true, port: 4001
config :epi_contacts, EpiContacts, signer: EpiContacts.SignatureMock, ttl: 250
config :epi_contacts, EpiContacts.PostContactWorker, commcare_verification_sleep: 0
config :epi_contacts, Oban, crontab: false, queues: false, plugins: false

config :epi_contacts,
  environment_name: "test",
  secure_session_cookies: false,
  sql_sandbox: true,
  http_client: EpiContacts.HTTPoisonMock,
  commcare_client: CommcareClientBehaviourMock,
  metrics_api: MetricsAPIBehaviourMock,
  analytics_client: AnalyticsClientBehaviourMock,
  posthog_client: AnalyticsClientBehaviourMock,
  analytics_reporter: AnalyticsReporterBehaviourMock,
  analytics_reporter_application_name: :share_my_contacts

config :phoenix_integration, endpoint: EpiContactsWeb.Endpoint

config :sentry,
  included_environments: [:test]
