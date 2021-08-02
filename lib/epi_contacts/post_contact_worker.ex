defmodule EpiContacts.PostContactWorker do
  @moduledoc """
  Oban worker that posts contacts gathered by the questionnaire back to commcare.
  """

  use Oban.Worker, queue: :default
  require Logger

  alias EpiContacts.{PatientCase, Contact}
  alias EpiContacts.Commcare.Client, as: CommcareClient

  @impl Oban.Worker
  def perform(%_{args: %{"patient_case" => patient_case, "contact" => contact}}),
    do: CommcareClient.post_contact(patient_case, Contact.from_string_map(contact))

  def enqueue_contacts(%{contacts: contacts, patient_case: patient_case}) do
    for contact <- contacts do
      contact = %Contact{contact | contact_id: PatientCase.generate_contact_id(patient_case)}

      %{patient_case: patient_case, contact: contact}
      |> __MODULE__.new()
      |> Oban.insert()
      |> log_insert(contact, patient_case)
    end

    :ok
  end

  defp log_insert({:ok, _job}, contact, patient_case) do
    domain = PatientCase.domain(patient_case)
    case_id = PatientCase.case_id(patient_case)

    Logger.info("contact_enqueued", %{
      commcare_domain: domain,
      commcare_case_id: case_id,
      contact_id: contact.contact_id
    })
  end

  defp log_insert({:error, changeset}, contact, patient_case) do
    errors = EpiContacts.Utils.traverse_errors(changeset)
    domain = PatientCase.domain(patient_case)
    case_id = PatientCase.case_id(patient_case)

    Logger.error("contact_not_enqueued", %{
      commcare_domain: domain,
      commcare_case_id: case_id,
      contact_id: contact.contact_id,
      errors: errors
    })
  end
end
