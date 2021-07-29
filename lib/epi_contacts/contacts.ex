defmodule EpiContacts.Contacts do
  @moduledoc """
  Contains business logic for submitting contacts to the contact tracing service
  """
  require Logger

  alias EpiContacts.PatientCase

  def submit_contacts(contacts, patient_case) do
    number_of_contacts = length(contacts)

    Logger.info("submit_contacts", %{number_of_contacts: number_of_contacts})

    enqueue_contacts(%{contacts: contacts, patient_case: patient_case})

    analytics_reporter().report_contacts_submission(
      contacts_count: number_of_contacts,
      patient_case: patient_case,
      timestamp: DateTime.utc_now()
    )
  end

  defp analytics_reporter, do: Application.get_env(:epi_contacts, :analytics_reporter)

  defp enqueue_contacts(%{contacts: contacts, patient_case: patient_case}) do
    ts = DateTime.utc_now() |> DateTime.to_unix() |> to_string()
    batch_id = PatientCase.transaction_id(patient_case) <> "-" <> ts

    contacts
    |> Enum.map(&%{contact: &1, patient_case: patient_case})
    |> EpiContacts.PostContactsBatch.new_batch(batch_id: batch_id)
    |> Oban.insert_all()
  end
end
