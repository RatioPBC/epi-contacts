defmodule EpiContacts.Monitoring.AnalyticsReporterBehaviour do
  @moduledoc """
  Provides a mockable interface around analytics reporting
  """
  @callback setup() :: :ok
  @callback report_unauthenticated_page_visit(page_identifier: atom(), timestamp: DateTime.t()) ::
              :ok | :error
  @callback report_page_visit(page_identifier: atom(), patient_case: map(), timestamp: DateTime.t()) ::
              :ok | :error
  @callback report_sms_triggered(patient_case: map(), reason: String.t(), timestamp: DateTime.t()) :: :ok | :error
  @callback report_contacts_submission(contacts_count: integer(), patient_case: map(), timestamp: DateTime.t()) ::
              :ok | :error
end
