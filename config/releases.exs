# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

config :epi_contacts, EpiContactsWeb.Endpoint,
  check_origin: false,
  http: [transport_options: [socket_opts: [:inet6]]],
  root: ".",
  server: true,
  url: [scheme: "https"]

config :epi_contacts, EpiContacts.Repo,
  pool_size: "POOL_SIZE" |> System.get_env("60") |> String.to_integer(),
  show_sensitive_data_on_connection_error: false,
  ssl: System.get_env("DBSSL", "true") == "true",
  connection_info: System.fetch_env!("DATABASE_SECRET")

defmodule SentryConfig do
  def ca_bundle() do
    System.get_env("SENTRY_CA_BUNDLE")
  end

  def hackney_opts(bundle \\ ca_bundle())
  def hackney_opts(nil), do: []
  def hackney_opts(cert) when is_binary(cert), do: [ssl_options: [cacertfile: cert]]
end

# Configured in EpiContacts.Application.configure_sentry/0
config :sentry,
  included_environments: [:staging, :prod]

config :epi_contacts,
  revision_date_epoch_seconds: System.get_env("REVISION_DATE_EPOCH_SECONDS"),
  release_level: System.fetch_env!("RELEASE_LEVEL"),
  sentry_ca_bundle: System.fetch_env!("SENTRY_CA_BUNDLE"),
  sentry_dsn: System.fetch_env!("SENTRY_DSN"),
  secure_id_key: System.fetch_env!("SECURE_ID_KEY"),
  posthog_api_key: System.get_env("POSTHOG_API_KEY"),
  posthog_api_url: System.get_env("POSTHOG_API_URL"),
  encryption_key: System.fetch_env!("ENCRYPTION_KEY"),
  commcare_api_token: System.fetch_env!("COMMCARE_API_TOKEN"),
  commcare_username: System.fetch_env!("COMMCARE_USERNAME"),
  commcare_user_id: System.fetch_env!("COMMCARE_USER_ID")

config :epi_contacts, EpiContactsWeb.Endpoint,
  basic_auth_password: System.fetch_env!("BASIC_AUTH_PASSWORD"),
  basic_auth_username: System.fetch_env!("BASIC_AUTH_USERNAME"),
  webhook_user: System.fetch_env!("WEBHOOK_USER"),
  webhook_pass: System.fetch_env!("WEBHOOK_PASS"),
  live_view: [signing_salt: System.fetch_env!("LIVE_VIEW_SIGNING_SALT")],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  url: [host: System.fetch_env!("CANONICAL_HOST")]

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :epi_contacts, EpiContactsWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
