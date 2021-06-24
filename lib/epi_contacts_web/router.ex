defmodule EpiContactsWeb.Router do
  use EpiContactsWeb, :router

  import EpiContactsWeb.AdminAuth
  use Plug.ErrorHandler
  use Sentry.Plug

  import Oban.Web.Router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {EpiContactsWeb.LayoutView, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_current_admin)
  end

  pipeline :api do
    plug(:accepts, ["json"])
    plug(:webhook_basic_auth)
  end

  pipeline :protected do
    plug(:require_authenticated_admin)
  end

  pipeline :questionnaire do
    plug(EpiContactsWeb.Plugs.CommcareInfoLoader)
  end

  pipeline :locale do
    plug(EpiContactsWeb.Plugs.Locale)
  end

  scope "/api/commcare", EpiContactsWeb do
    pipe_through(:api)
    post("/forwarding", CommcareApiController, :webhook)
  end

  scope "/", EpiContactsWeb do
    pipe_through([:browser, :locale, :questionnaire])

    live("/s/:secure_id", QuestionnaireLive, :confirm_identity)
    live("/start/:commcare_domain/:case_id", QuestionnaireLive, :confirm_identity)

    live("/add-contact", QuestionnaireLive, :add_contact)
    live("/contact-list", QuestionnaireLive, :contact_list)

    live("/test-results", QuestionnaireLive, :test_results)
    live("/prep", QuestionnaireLive, :prep)
    live("/house", QuestionnaireLive, :house)
    live("/social", QuestionnaireLive, :social)
    live("/review", QuestionnaireLive, :review)
    live("/confirmation", QuestionnaireLive, :confirmation)
  end

  scope "/", EpiContactsWeb do
    pipe_through([:browser, :locale])

    get("/", PageController, :index)
    get("/error", PageController, :error)
    get("/expired", PageController, :link_expired)
    get("/minor", PageController, :minor)
    get("/privacy", PageController, :privacy)
    get("/unable_to_verify", PageController, :unable_to_verify)
  end

  scope "/", EpiContactsWeb do
    pipe_through(:browser)

    get("/healthcheck", HealthCheckController, :index)
    get("/locale", PageController, :locale)
  end

  scope "/private" do
    pipe_through([:browser, :private_csp, :protected])

    live_dashboard("/dashboard", metrics: EpiContactsWeb.Telemetry)
    oban_dashboard("/oban")
    forward("/feature-flags", FunWithFlags.UI.Router, namespace: "private/feature-flags")
  end

  def private_csp(conn, _opts) do
    delete_resp_header(conn, "content-security-policy")
  end

  def protected_via_basic_auth(conn, _opts) do
    Plug.BasicAuth.basic_auth(
      conn,
      username: EpiContactsWeb.Endpoint.config(:basic_auth_username),
      password: EpiContactsWeb.Endpoint.config(:basic_auth_password)
    )
  end

  def webhook_basic_auth(conn, _opts) do
    Plug.BasicAuth.basic_auth(
      conn,
      username: EpiContactsWeb.Endpoint.config(:webhook_user),
      password: EpiContactsWeb.Endpoint.config(:webhook_pass)
    )
  end

  ## Authentication routes

  scope "/", EpiContactsWeb do
    pipe_through([:browser, :redirect_if_admin_is_authenticated])

    get("/admins/log_in", AdminSessionController, :new)
    post("/admins/log_in", AdminSessionController, :create)
  end

  scope "/", EpiContactsWeb do
    pipe_through([:browser])
    delete("/admins/log_out", AdminSessionController, :delete)
  end
end
