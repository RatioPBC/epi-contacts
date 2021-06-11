defmodule EpiContactsWeb.PageController do
  use EpiContactsWeb, :controller
  alias EpiContacts.PatientCase

  def index(conn, _params) do
    log_and_render(conn, "index.html")
  end

  def privacy(conn, _params) do
    log_and_render(conn, "privacy.html")
  end

  def minor(conn, _params) do
    case_id = Plug.Conn.get_session(conn, :case_id)
    domain = Plug.Conn.get_session(conn, :domain)

    {:ok, patient_case} = commcare_client().get_case(domain, case_id)
    initials = PatientCase.initials(patient_case)

    end_of_infectious_period =
      patient_case
      |> PatientCase.end_of_infectious_period()
      |> to_string()

    clear_session_and_render(conn, "minor.html",
      case_initials: initials,
      end_of_infectious_period: end_of_infectious_period
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
      timestamp: DateTime.utc_now()
    )

    conn
  end

  defp analytics_reporter, do: Application.get_env(:epi_contacts, :analytics_reporter)
  defp commcare_client, do: Application.get_env(:epi_contacts, :commcare_client)
end
