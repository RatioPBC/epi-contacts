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
  ssl: System.get_env("DBSSL", "true") == "true",
  show_sensitive_data_on_connection_error: false

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
  analytics_reporter_application_name:
    "ANALYTICS_REPORTER_APPLICATION_NAME" |> System.get_env("share_my_contacts") |> String.to_atom()

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :epi_contacts, EpiContactsWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
