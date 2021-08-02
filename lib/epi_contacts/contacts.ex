defmodule EpiContacts.Contacts do
  @moduledoc """
  Contains business logic for submitting contacts to the contact tracing service
  """
  require Logger

  alias EpiContacts.{PatientCase, PostContactWorker}

  def submit_contacts(contacts, patient_case) do
    contacts_count = length(contacts)
    domain = PatientCase.domain(patient_case)
    case_id = PatientCase.case_id(patient_case)

    Logger.info("submit_contacts", %{contacts_count: contacts_count, commcare_domain: domain, commcare_case_id: case_id})

    PostContactWorker.enqueue_contacts(%{contacts: contacts, patient_case: patient_case})

    analytics_reporter().report_contacts_submission(
      contacts_count: contacts_count,
      patient_case: patient_case,
      timestamp: DateTime.utc_now()
    )
  end

  defp analytics_reporter, do: Application.get_env(:epi_contacts, :analytics_reporter)
end
