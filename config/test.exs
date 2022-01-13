import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.

config :epi_contacts, EpiContacts.Repo,
  [
    username: System.get_env("POSTGRES_USER", "cc"),
    password: System.get_env("POSTGRES_PASSWORD", "abc123"),
    hostname: System.get_env("POSTGRES_HOST", "localhost"),
    port: 5432,
    database: System.get_env("POSTGRES_DB", "epi_contacts_test#{System.get_env("MIX_TEST_PARTITION")}"),
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

config :epi_contacts, EpiContactsWeb.Endpoint, server: true, port: 4002
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

config :epi_contacts,
  # revision_date_epoch_seconds: "1601918940",
  release_level: "test",
  sentry_ca_bundle: nil,
  sentry_dsn: nil,
  secure_id_key: "6QA+ueojBBxcq7Twgk70OeGqxBdVJUOHiQ7H3kKimCc=",
  posthog_api_key: nil,
  posthog_api_url: nil,
  encryption_key: "+hIAz8JzU7GWSh06wTtsJy835GzSG4xOr8wxmupJktI=",
  commcare_api_token: "johndoe@example.com:3923c69760a6f9e4f46a069c2691083010cbb57d",
  commcare_username: "geometer_user_1",
  commcare_user_id: "abc123"

config :epi_contacts, EpiContactsWeb.Endpoint,
  basic_auth_password: "password", # anything for dev
  basic_auth_username: "ratiopbc", # anything for dev
  webhook_user: "AzureDiamond",
  webhook_pass: "hunter2",
  live_view: [signing_salt: "GdwB9kX0y82QGeQzNd2sIyV1clIY9qrWkTgGzv70ATjaYx9+wde2Q005So9Qu30y"],
  secret_key_base: "PoZbi70MnJojDJ2W41mccqWsFaGa2Ea6uctuWxzaYd9I0XZceVT3lIGVLtzSCTw2",
  url: [host: "localhost"]

config :phoenix_integration, endpoint: EpiContactsWeb.Endpoint

config :sentry,
  included_environments: [:test]
