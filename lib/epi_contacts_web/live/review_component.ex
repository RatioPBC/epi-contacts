defmodule EpiContactsWeb.ReviewComponent do
  @moduledoc """
  live component for reviewing user's input to the questionnaire
  """

  use EpiContactsWeb, :live_component

  alias EpiContacts.Contacts
  alias EpiContacts.Review
  alias EpiContactsWeb.QuestionnaireView

  def mount(socket) do
    review = %Review{}
    changeset = Review.validate(review, %{})

    socket =
      socket
      |> assign(:changeset, changeset)
      |> assign(:review, review)

    {:ok, socket}
  end

  def render(assigns) do
    Phoenix.View.render(QuestionnaireView, "review_component.html", assigns)
  end

  def handle_event(
        "submit",
        %{"review" => review_params},
        %{assigns: %{patient_case: patient_case, contacts: contacts, review: review}} = socket
      ) do
    changeset = Review.validate(review, review_params)

    socket =
      case Ecto.Changeset.apply_action(changeset, :update) do
        {:ok, _} ->
          Contacts.submit_contacts(contacts, patient_case)
          push_patch(socket, to: Routes.questionnaire_path(socket, :confirmation))

        {:error, changeset} ->
          assign(socket, :changeset, changeset)
      end

    {:noreply, socket}
  end
end
