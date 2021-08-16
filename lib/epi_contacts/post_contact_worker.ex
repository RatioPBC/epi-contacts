defmodule EpiContacts.PostContactWorker do
  @moduledoc """
  Oban worker that posts contacts gathered by the questionnaire back to commcare.
  """

  use Oban.Worker, queue: :default
  require Logger

  alias EpiContacts.{PatientCase, Contact}
  alias EpiContacts.Commcare.Client, as: CommcareClient

  @impl Oban.Worker
  def perform(%_{
        args: %{
          "patient_case" => patient_case,
          "contact" => contact,
          "envelope_id" => envelope_id,
          "case_id" => case_id
        },
        attempt: attempt
      }) do
    case CommcareClient.post_contact(patient_case, Contact.from_string_map(contact),
           case_id: case_id,
           envelope_id: envelope_id
         ) do
      {:error, :timeout} ->
        {:snooze, (1 + attempt) * 60}

      response ->
        response
    end
  end

  def enqueue_contacts(%{contacts: contacts, patient_case: patient_case}) do
    for contact <- contacts do
      contact = %Contact{contact | contact_id: PatientCase.generate_contact_id(patient_case)}
      case_id = Ecto.UUID.generate()
      envelope_id = Ecto.UUID.generate()

      %{patient_case: patient_case, contact: contact, envelope_id: envelope_id, case_id: case_id}
      |> __MODULE__.new()
      |> Oban.insert()
      |> log_insert(contact)
    end

    :ok
  end

  defp log_insert({:ok, _job}, contact) do
    Logger.info("contact_enqueued", %{
      contact_id: contact.contact_id
    })
  end

  defp log_insert({:error, changeset}, contact) do
    errors = EpiContacts.Utils.traverse_errors(changeset)

    Logger.error("contact_not_enqueued", %{
      contact_id: contact.contact_id,
      errors: errors
    })
  end
end
