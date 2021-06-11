defmodule EpiContactsWeb.AddContactComponent do
  @moduledoc """
  live component for adding a contact in the questionnaire
  """

  use EpiContactsWeb, :live_component
  alias EpiContacts.{Contact, PatientCase}
  alias EpiContactsWeb.QuestionnaireView

  @impl true
  def preload([assigns]) do
    patient_case = assigns.patient_case
    contact = %Contact{primary_language: PatientCase.primary_language(patient_case)}
    changeset = Contact.change(contact, %{})
    exposed_on_select_options = QuestionnaireView.exposed_on_select_options(patient_case)

    [
      assigns
      |> Map.put(:contact, contact)
      |> Map.put(:changeset, changeset)
      |> Map.put(:exposed_on_select_options, exposed_on_select_options)
    ]
  end

  @impl true
  def mount(socket), do: ok(socket)

  @impl true
  def render(assigns) do
    Phoenix.View.render(QuestionnaireView, "add_contact_component.html", assigns)
  end

  @impl true
  def handle_event("validate", %{"contact" => contact_params}, socket),
    do: socket |> assign(:changeset, validate(contact_params, socket)) |> noreply()

  def handle_event("submit", %{"contact" => contact_params}, socket) do
    contact_params
    |> validate(socket)
    |> Ecto.Changeset.apply_action(:update)
    |> case do
      {:ok, contact} ->
        send(self(), {:added_contact, contact})
        noreply(socket)

      {:error, changeset} ->
        socket |> assign(:changeset, changeset) |> noreply()
    end
  end

  defp validate(params, %{assigns: %{contact: contact, patient_case: patient_case}}) do
    contact
    |> Contact.change(params, patient_case)
    |> Map.put(:action, :validate)
  end
end
