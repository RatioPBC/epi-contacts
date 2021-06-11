defmodule EpiContactsWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :epi_contacts

  alias EpiContacts.Config.JsonEnv
  alias Vapor.Provider.Dotenv
  alias Vapor.Provider.Env

  @secure_session_cookies Application.compile_env!(:epi_contacts, :secure_session_cookies)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_epi_contacts_key",
    secure: @secure_session_cookies,
    signing_salt: "zdpxeIXe",
    same_site: "Lax",
    #
    # GW: This should ideally be set as an environment variable.
    # HOWEVER, it's not immediately clear to me when the socket() and plug() macros below are evaluated (are they
    # evaluated at compile time? can you give it as a run-time option somehow?)
    # So we'll hard-wire this value for now, and perhaps move it to an env variable later:
    encryption_salt: "pma6fx98f9pfuSuMTPLKv44OJDq+XNA8Q2HzmHw1SPNRv6lVw4n2Dps8c9FZYzVY"
  ]

  socket("/socket", EpiContactsWeb.UserSocket,
    websocket: [timeout: 45_000],
    longpoll: false
  )

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(:ensure_browser_headers)

  plug(
    EpiContactsWeb.Plugs.ContentSecurityPolicyHeader,
    Application.get_env(:epi_contacts, EpiContactsWeb.Endpoint)[:content_security_policy_options]
  )

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :epi_contacts,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :epi_contacts)
  end

  plug(Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"
  )

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)

  plug(EpiContactsWeb.Router)

  if Application.get_env(:epi_contacts, :sql_sandbox) do
    plug(Phoenix.Ecto.SQL.Sandbox)
  end

  def init(:supervisor, opts), do: {:ok, load_system_env(opts)}

  defp ensure_browser_headers(conn, _opts) do
    environment_specified_headers = Application.get_env(:epi_contacts, EpiContactsWeb.Endpoint)

    conn
    |> put_resp_header("cache-control", "private, no-store")
    |> put_resp_header("strict-transport-security", environment_specified_headers[:strict_transport_security])
    |> put_resp_header("x-content-type-options", "nosniff")
  end

  defp load_system_env(opts) do
    providers = [
      %Dotenv{},
      %Env{
        bindings: [
          {:basic_auth_username, "BASIC_AUTH_USERNAME", default: ""},
          {:basic_auth_password, "BASIC_AUTH_PASSWORD", default: ""},
          {:webhook_user, "WEBHOOK_USER", default: ""},
          {:webhook_pass, "WEBHOOK_PASS", default: ""},
          {:canonical_host, "CANONICAL_HOST", default: "localhost"},
          {:live_view_signing_salt, "LIVE_VIEW_SIGNING_SALT", default: ""},
          {:port, "PORT", default: "4000"},
          {:secret_key_base, "SECRET_KEY_BASE", default: ""}
        ]
      },
      %JsonEnv{
        variable: "SECRETS",
        bindings: [
          {:basic_auth_password, "BASIC_AUTH_PASSWORD"},
          {:basic_auth_username, "BASIC_AUTH_USERNAME"},
          {:webhook_user, "WEBHOOK_USER"},
          {:webhook_pass, "WEBHOOK_PASS"},
          {:canonical_host, "CANONICAL_HOST"},
          {:live_view_signing_salt, "LIVE_VIEW_SIGNING_SALT"},
          {:port, "PORT"},
          {:secret_key_base, "SECRET_KEY_BASE"}
        ]
      }
    ]

    config = Vapor.load!(providers, [])

    Keyword.merge(opts,
      basic_auth_password: config.basic_auth_password,
      basic_auth_username: config.basic_auth_username,
      webhook_user: config.webhook_user,
      webhook_pass: config.webhook_pass,
      http: [port: config.port],
      live_view: [signing_salt: config.live_view_signing_salt],
      secret_key_base: config.secret_key_base,
      url: [host: config.canonical_host]
    )
  end
end
