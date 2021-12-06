defmodule EpiContacts.Monitoring.AnalyticsReporter do
  require Logger

  alias EpiContacts.Monitoring.AnalyticsReporterBehaviour
  alias EpiContacts.PatientCase

  @behaviour AnalyticsReporterBehaviour

  @moduledoc """
  Reports analytics events to an analytics service (e.g. PostHog)
  """

  # NOTE: when adding new event types, make sure to add them to @events_sent_to_analytics_service
  @application_name Application.compile_env(:epi_contacts, :analytics_reporter_application_name, :share_my_contacts)
  @contacts_submission_event [@application_name, :analytics, :contacts_submission]
  @page_visit_event [@application_name, :analytics, :page_visit]
  @unauthenticated_page_visit_event [@application_name, :analytics, :unauthenticated_page_visit]
  @sms_triggered_event [@application_name, :analytics, :sms_triggered]
  @events_sent_to_analytics_service [
    @contacts_submission_event,
    @page_visit_event,
    @unauthenticated_page_visit_event,
    @sms_triggered_event
  ]

  @reporter_handler_id "analytics-reporter"
  def reporter_handler_id, do: @reporter_handler_id

  @impl AnalyticsReporterBehaviour
  def setup do
    if analytics_client().configuration_present?() do
      :telemetry.attach_many(
        @reporter_handler_id,
        @events_sent_to_analytics_service,
        &handle_event/4,
        nil
      )

      :ok
    else
      Logger.error("PostHog client configuration is missing")
      :error
    end
  end

  def handle_event(@page_visit_event = event_type, _measure, meta, _config) do
    event_metadata = %{
      distinct_id: meta[:external_id],
      commcare_domain: meta[:domain],
      commcare_case_id: meta[:commcare_case_id],
      page: meta[:page],
      reason: meta[:reason],
      locale: meta[:locale]
    }

    report_event(event_type, event_metadata, meta[:timestamp])
  end

  def handle_event(@unauthenticated_page_visit_event = event_type, _measure, meta, _config) do
    event_metadata = %{
      page: meta[:page],
      distinct_id: "unauthenticated",
      locale: meta[:locale]
    }

    report_event(event_type, event_metadata, meta[:timestamp])
  end

  def handle_event(@sms_triggered_event = event_type, _measure, meta, _config) do
    event_metadata = %{
      distinct_id: meta[:external_id],
      commcare_domain: meta[:domain],
      commcare_case_id: meta[:commcare_case_id],
      reason: meta[:reason]
    }

    report_event(event_type, event_metadata, meta[:timestamp])
  end

  def handle_event(@contacts_submission_event = event_type, _measure, meta, _config) do
    event_metadata = %{
      distinct_id: meta[:external_id],
      commcare_domain: meta[:domain],
      commcare_case_id: meta[:commcare_case_id],
      contacts_count: meta[:contacts_count],
      reason: meta[:reason]
    }

    report_event(event_type, event_metadata, meta[:timestamp])
  end

  defp report_event(event_type, metadata, timestamp) do
    event_name = stringify_event_type(event_type)

    metadata =
      metadata
      |> Map.merge(%{
        environment: Application.get_env(:epi_contacts, :environment_name) |> Atom.to_string(),
        application: to_string(@application_name)
      })

    analytics_client().capture(event_name, metadata, timestamp)
  end

  defp stringify_event_type(event_type) do
    Enum.map_join(event_type, ".", &to_string/1)
  end

  @impl AnalyticsReporterBehaviour
  def report_contacts_submission(
        contacts_count: contacts_count,
        patient_case: patient_case,
        timestamp: timestamp
      )
      when is_map(patient_case) do
    smc_trigger_reason = PatientCase.smc_trigger_reason(patient_case)

    execute_telemetry(
      event_name: @contacts_submission_event,
      patient_case: patient_case,
      meta: %{
        contacts_count: contacts_count,
        timestamp: timestamp,
        reason: smc_trigger_reason
      }
    )
  end

  def report_contacts_submission(contacts_count: _, patient_case: _, timestamp: _), do: :error

  @impl AnalyticsReporterBehaviour
  def report_page_visit(
        page_identifier: page_identifier,
        patient_case: patient_case,
        timestamp: timestamp,
        locale: locale
      )
      when is_map(patient_case) do
    smc_trigger_reason = PatientCase.smc_trigger_reason(patient_case)

    execute_telemetry(
      event_name: @page_visit_event,
      patient_case: patient_case,
      meta: %{
        page: page_identifier,
        timestamp: timestamp,
        reason: smc_trigger_reason,
        locale: locale
      }
    )
  end

  def report_page_visit(page_identifier: _, patient_case: _, timestamp: _, locale: _), do: :error

  @impl AnalyticsReporterBehaviour
  def report_unauthenticated_page_visit(page_identifier: page_identifier, timestamp: timestamp, locale: locale) do
    execute_telemetry(
      event_name: @unauthenticated_page_visit_event,
      meta: %{
        page: page_identifier,
        timestamp: timestamp,
        locale: locale
      }
    )
  end

  @impl AnalyticsReporterBehaviour
  def report_sms_triggered(patient_case: patient_case, reason: reason, timestamp: timestamp) do
    execute_telemetry(
      event_name: @sms_triggered_event,
      patient_case: patient_case,
      meta: %{
        timestamp: timestamp,
        reason: reason
      }
    )
  end

  defp execute_telemetry(event_name: event_name, patient_case: patient_case, meta: meta) do
    with external_id when not is_nil(external_id) <- PatientCase.external_id(patient_case),
         domain when not is_nil(domain) <- PatientCase.domain(patient_case),
         commcare_case_id when not is_nil(commcare_case_id) <- PatientCase.case_id(patient_case) do
      :telemetry.execute(
        event_name,
        %{},
        %{
          external_id: external_id,
          domain: domain,
          commcare_case_id: commcare_case_id
        }
        |> Map.merge(meta)
      )

      :ok
    else
      _ -> :error
    end
  end

  defp execute_telemetry(event_name: event_name, meta: meta) do
    :telemetry.execute(
      event_name,
      %{},
      meta
    )

    :ok
  end

  defp analytics_client do
    Application.get_env(:epi_contacts, :analytics_client)
  end
end
