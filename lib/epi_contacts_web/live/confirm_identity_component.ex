defmodule EpiContactsWeb.ConfirmIdentityComponent do
  @moduledoc """
  live component for confirming user identity in the questionnaire
  """

  use EpiContactsWeb, :live_component
  alias EpiContacts.ConfirmIdentity

  def mount(socket) do
    confirm_identity = %ConfirmIdentity{}
    changeset = ConfirmIdentity.changeset(confirm_identity, %{})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:confirm_identity, confirm_identity)
      |> assign(:is_locked_out, false)

    {:ok, socket}
  end

  def render(assigns) do
    Phoenix.View.render(EpiContactsWeb.QuestionnaireView, "confirm_identity_component.html", assigns)
  end

  def handle_event(
        "submit",
        %{"confirm_identity" => confirm_identity_params},
        %{assigns: %{patient_case: patient_case, confirm_identity: confirm_identity}} = socket
      ) do
    socket =
      case ConfirmIdentity.verify_correct_date_of_birth(confirm_identity, confirm_identity_params, patient_case) do
        {:ok, _} ->
          push_patch(socket, to: questionnaire_path(socket, :test_results))

        {:error, :locked_out} ->
          socket
          |> assign(:is_locked_out, true)
          |> assign(:changeset, ConfirmIdentity.changeset(%ConfirmIdentity{}, %{}))

        {:error, changeset} ->
          socket
          |> assign(:is_locked_out, false)
          |> assign(:changeset, changeset)
      end

    {:noreply, socket}
  end
end
