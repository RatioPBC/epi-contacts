defmodule EpiContactsWeb.PageController do
  use EpiContactsWeb, :controller
  alias EpiContacts.PatientCase

  defmodule LocaleForm do
    import Ecto.Changeset

    defstruct [:locale, :redirect_to]

    @types %{locale: :string, redirect_to: :string}
    @required [:locale]
    @allowed [:locale, :redirect_to]

    @doc """
    Creates a changeset for the form.
    """
    def changeset(params) do
      {%__MODULE__{}, @types}
      |> cast(params, @allowed)
      |> validate_required(@required)
    end
  end

  def index(conn, _params) do
    log_and_render(conn, "index.html")
  end

  def locale(conn, params) do
    render(conn, "locale.html", changeset: LocaleForm.changeset(params))
  end

  def set_locale(conn, %{"locale_form" => locale_params}) do
    changeset = LocaleForm.changeset(locale_params)

    if changeset.valid? do
      locale = Ecto.Changeset.get_field(changeset, :locale)
      redirect_to = Ecto.Changeset.get_field(changeset, :redirect_to)

      conn
      |> put_session(:locale, locale)
      |> log_page_view()
      |> redirect(to: redirect_to)
      |> halt()
    else
      conn
      |> put_flash(:error, gettext("We're sorry, but something went wrong."))
      |> render("locale.html", changeset: LocaleForm.changeset(locale_params))
    end
  end

  def privacy(conn, _params) do
    log_and_render(conn, "privacy.html")
  end

  def minor(conn, _params) do
    case_id = Plug.Conn.get_session(conn, :case_id)
    domain = Plug.Conn.get_session(conn, :domain)

    {:ok, patient_case} = commcare_client().get_case(domain, case_id)
    initials = PatientCase.initials(patient_case)

    clear_session_and_render(conn, "minor.html",
      case_initials: initials,
      patient_case: patient_case
    )
  end

  def link_expired(conn, _params) do
    clear_session_and_render(conn, "link_expired.html")
  end

  def error(conn, _params) do
    clear_session_and_render(conn, "error.html")
  end

  def unable_to_verify(conn, _params) do
    clear_session_and_render(conn, "unable_to_verify.html")
  end

  defp clear_session_and_render(conn, template, assigns \\ []) do
    conn |> Plug.Conn.clear_session() |> log_and_render(template, assigns)
  end

  defp log_and_render(conn, template, assigns \\ []) do
    conn |> log_page_view() |> render(template, assigns)
  end

  defp log_page_view(conn) do
    analytics_reporter().report_unauthenticated_page_visit(
      page_identifier: conn.private.phoenix_action,
      timestamp: DateTime.utc_now(),
      locale: get_session(conn, :locale)
    )

    conn
  end

  defp analytics_reporter, do: Application.get_env(:epi_contacts, :analytics_reporter)
  defp commcare_client, do: Application.get_env(:epi_contacts, :commcare_client)
end
