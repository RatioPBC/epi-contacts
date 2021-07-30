defmodule EpiContacts.Contacts do
  @moduledoc """
  Contains business logic for submitting contacts to the contact tracing service
  """
  require Logger

  alias EpiContacts.PatientCase

  def submit_contacts(contacts, patient_case) do
    enqueue_contacts(contacts, patient_case)
    log_contacts_submitted(patient_case, contacts)
  end

  defp analytics_reporter, do: Application.get_env(:epi_contacts, :analytics_reporter)

  defp enqueue_contacts(contacts, patient_case) do
    case_id = PatientCase.case_id(patient_case)
    domain = PatientCase.domain(patient_case)
    ts = DateTime.utc_now() |> DateTime.to_unix() |> to_string()
    batch_id = PatientCase.transaction_id(patient_case) <> "-" <> ts

    contacts
    |> Enum.map(&%{contact: &1, patient_case: patient_case, domain: domain, case_id: case_id})
    |> EpiContacts.PostContactsBatch.new_batch(batch_id: batch_id)
    |> Oban.insert_all()
  end

  defp log_contacts_submitted(patient_case, contacts) do
    number_of_contacts = length(contacts)
    case_id = PatientCase.case_id(patient_case)
    domain = PatientCase.domain(patient_case)

    Logger.info("submit_contacts", %{number_of_contacts: number_of_contacts, case_id: case_id, domain: domain})

    analytics_reporter().report_contacts_submission(
      contacts_count: number_of_contacts,
      patient_case: patient_case,
      timestamp: DateTime.utc_now()
    )
  end
end
