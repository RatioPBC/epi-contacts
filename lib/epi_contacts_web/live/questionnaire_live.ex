defmodule EpiContactsWeb.QuestionnaireLive do
  @moduledoc """
  live view responsible for collecting contacts from inbound cases
  """

  use EpiContactsWeb, :live_view
  require Logger
  alias EpiContacts.{Gettext, PatientCase, Contact}
  alias EpiContactsWeb.QuestionnaireView

  @components ~w{add_contact confirm_identity review}a

  @impl true
  def mount(_params, %{"domain" => domain, "case_id" => case_id, "locale" => locale}, socket) do
    Gettext.put_locale(locale)

    with {:patient_or_contacts_missing, socket} <- has_patient_case_and_assigns(socket),
         {:ok, patient_case} <- commcare_client().get_case(domain, case_id),
         :date_of_birth_present <- has_date_of_birth(patient_case),
         :not_a_minor <- minor(patient_case) do
      assign(socket, %{patient_case: patient_case, contacts: [], skip_path: nil})
    else
      {:patient_or_contacts_present, socket} ->
        socket

      {:is_minor, patient_case} ->
        socket
        |> assign(patient_case: patient_case)
        |> push_redirect(to: Routes.page_path(socket, :minor))

      :date_of_birth_missing ->
        push_redirect(socket, to: Routes.page_path(socket, :unable_to_verify))

      {:error, reason} ->
        Logger.warn("case not found: #{domain}/#{case_id} - #{reason}")

        push_redirect(socket, to: Routes.page_path(socket, :error))
    end
    |> ok()
  end

  defp minor(patient_case) do
    case PatientCase.smc_trigger_reason(patient_case) do
      "pre_ci_minor" -> {:is_minor, patient_case}
      _ -> :not_a_minor
    end
  end

  defp has_date_of_birth(patient_case) do
    if PatientCase.has_date_of_birth?(patient_case),
      do: :date_of_birth_present,
      else: :date_of_birth_missing
  end

  defp has_patient_case_and_assigns(%{assigns: assigns} = socket) do
    if assigns[:patient_case] && assigns[:contacts],
      do: {:patient_or_contacts_present, socket},
      else: {:patient_or_contacts_missing, socket}
  end

  @impl true
  def handle_params(path, _, socket) do
    socket |> log_page_view() |> assign_skip_path(path) |> noreply()
  end

  @impl true
  def render(%{live_action: component} = assigns)
      when component in @components do
    ~L"""
    <%= live_component @socket, to_module(component),
        id: component,
        patient_case: @patient_case,
        skip_path: @skip_path,
        contacts: @contacts %>
    """
  end

  def render(%{live_action: current_page} = assigns),
    do: Phoenix.View.render(QuestionnaireView, "#{current_page}.html", assigns)

  @impl true
  def handle_event("delete-contact", %{"index" => index}, %{assigns: %{contacts: contacts}} = socket) do
    socket
    |> assign(:contacts, List.delete_at(contacts, String.to_integer(index)))
    |> noreply()
  end

  @impl true
  def handle_info({:added_contact, contact = %Contact{}}, %{assigns: %{contacts: contacts}} = socket) do
    socket
    |> assign(:contacts, [contact | contacts])
    |> push_patch(to: questionnaire_path(socket, :contact_list))
    |> noreply()
  end

  def to_module(component_atom) do
    base = component_atom |> Atom.to_string() |> Macro.camelize()
    Module.concat(EpiContactsWeb, "#{base}Component")
  end

  # # #

  defp assign_skip_path(socket, %{"skip_path" => skip_path}),
    do: assign(socket, skip_path: String.to_existing_atom(skip_path))

  defp assign_skip_path(socket, _params), do: socket

  defp log_page_view(%{:connected? => true} = socket) do
    analytics_reporter().report_page_visit(
      page_identifier: socket.assigns.live_action,
      patient_case: socket.assigns.patient_case,
      timestamp: DateTime.utc_now()
    )

    socket
  end

  defp log_page_view(socket), do: socket

  defp analytics_reporter, do: Application.get_env(:epi_contacts, :analytics_reporter)

  defp commcare_client, do: Application.get_env(:epi_contacts, :commcare_client)
end
