defmodule EpiContacts.Monitoring.AnalyticsReporterTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog
  import Mox
  setup :verify_on_exit!

  alias EpiContacts.Monitoring.AnalyticsReporter
  alias EpiContacts.PatientCase

  @application "share_my_contacts"
  @commcare_case_id "case-123"
  @domain "domain"
  @environment "test"
  @external_id "http://commcare/domain/case/case-123"
  @page :homepage
  @timestamp "2021-01-19T22:46:02.194Z"
  @reason "pre_ci"

  describe "setup" do
    test "when analytics client configuration is missing, it logs an error" do
      expect(AnalyticsClientBehaviourMock, :configuration_present?, fn -> false end)

      assert capture_log(fn ->
               assert :error = AnalyticsReporter.setup()
             end) =~ "PostHog client configuration is missing"
    end

    test "when analytics client configuration is missing, it does not attach the telemetry handler" do
      expect(AnalyticsClientBehaviourMock, :configuration_present?, fn -> false end)

      assert :error = AnalyticsReporter.setup()
      assert {:error, :not_found} = :telemetry.detach(AnalyticsReporter.reporter_handler_id())
    end

    test "when analytics client configuration is present, it attaches the telemetry handler" do
      expect(AnalyticsClientBehaviourMock, :configuration_present?, fn -> true end)

      assert :ok = AnalyticsReporter.setup()
      assert :ok = :telemetry.detach(AnalyticsReporter.reporter_handler_id())
    end
  end

  def set_up_success_response(assertions_callback \\ fn _ -> nil end) do
    expect(AnalyticsClientBehaviourMock, :capture, fn event_name, metadata, timestamp ->
      assertions_callback.(event_name, metadata, timestamp)
      :ok
    end)
  end

  describe "handle_event with event type = contacts_submission" do
    test "it sends the event to PostHog" do
      set_up_success_response(fn event_name, metadata, timestamp ->
        assert event_name == "share_my_contacts.analytics.contacts_submission"

        assert metadata == %{
                 contacts_count: 2,
                 distinct_id: @external_id,
                 commcare_domain: @domain,
                 commcare_case_id: @commcare_case_id,
                 application: @application,
                 environment: @environment,
                 reason: @reason
               }

        assert timestamp == @timestamp
      end)

      event_type = [:share_my_contacts, :analytics, :contacts_submission]

      meta = %{
        contacts_count: 2,
        external_id: @external_id,
        timestamp: @timestamp,
        domain: @domain,
        commcare_case_id: @commcare_case_id,
        reason: @reason
      }

      assert :ok = AnalyticsReporter.handle_event(event_type, "some measurements", meta, "some config")
    end
  end

  describe "handle_event with event type = page_visit" do
    test "it sends the event to PostHog" do
      set_up_success_response(fn event_name, metadata, timestamp ->
        assert event_name == "share_my_contacts.analytics.page_visit"

        assert metadata == %{
                 page: @page,
                 distinct_id: @external_id,
                 commcare_domain: @domain,
                 commcare_case_id: @commcare_case_id,
                 application: @application,
                 environment: @environment,
                 reason: @reason
               }

        assert timestamp == @timestamp
      end)

      event_type = [:share_my_contacts, :analytics, :page_visit]

      meta = %{
        page: @page,
        external_id: @external_id,
        timestamp: @timestamp,
        domain: @domain,
        commcare_case_id: @commcare_case_id,
        reason: @reason
      }

      assert :ok = AnalyticsReporter.handle_event(event_type, "some measurements", meta, "some config")
    end
  end

  describe "handle_event with event type = unauthenticated_page_visit" do
    test "it sends the event to PostHog" do
      set_up_success_response(fn event_name, metadata, timestamp ->
        assert event_name == "share_my_contacts.analytics.unauthenticated_page_visit"

        assert metadata == %{
                 page: @page,
                 application: @application,
                 environment: @environment,
                 distinct_id: "unauthenticated"
               }

        assert timestamp == @timestamp
      end)

      event_type = [:share_my_contacts, :analytics, :unauthenticated_page_visit]

      meta = %{
        page: @page,
        timestamp: @timestamp
      }

      assert :ok = AnalyticsReporter.handle_event(event_type, "some measurements", meta, "some config")
    end
  end

  describe "handle_event with event type = sms_triggered" do
    test "it sends the event to PostHog" do
      set_up_success_response(fn event_name, metadata, timestamp ->
        assert event_name == "share_my_contacts.analytics.sms_triggered"

        assert metadata == %{
                 distinct_id: @external_id,
                 commcare_domain: @domain,
                 commcare_case_id: @commcare_case_id,
                 reason: @reason,
                 application: @application,
                 environment: @environment
               }

        assert timestamp == @timestamp
      end)

      event_type = [:share_my_contacts, :analytics, :sms_triggered]

      meta = %{
        external_id: @external_id,
        timestamp: @timestamp,
        domain: @domain,
        commcare_case_id: @commcare_case_id,
        reason: @reason
      }

      assert :ok = AnalyticsReporter.handle_event(event_type, "some measurements", meta, "some config")
    end
  end

  describe "report_contacts_submission" do
    setup %{test: test} do
      self = self()

      :ok =
        :telemetry.attach_many(
          "#{test}",
          [
            [:share_my_contacts, :analytics, :contacts_submission]
          ],
          fn name, measurements, metadata, _ ->
            send(self, {:telemetry_event, name, measurements, metadata})
          end,
          nil
        )

      patient_case =
        "test/fixtures/commcare/case-with-test-results-and-contacts.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["properties", "smc_trigger_reason"], @reason)

      timestamp = DateTime.utc_now()

      {:ok, patient_case: patient_case, timestamp: timestamp}
    end

    test "emits a telemetry event with properties extracted from the patient case", %{
      patient_case: patient_case,
      timestamp: timestamp
    } do
      assert :ok ==
               AnalyticsReporter.report_contacts_submission(
                 contacts_count: 2,
                 patient_case: patient_case,
                 timestamp: timestamp
               )

      expected_external_id = patient_case |> PatientCase.external_id()
      expected_domain = patient_case |> PatientCase.domain()
      expected_commcare_case_id = patient_case |> PatientCase.case_id()

      assert_receive {:telemetry_event, [:share_my_contacts, :analytics, :contacts_submission], %{},
                      %{
                        contacts_count: 2,
                        external_id: ^expected_external_id,
                        domain: ^expected_domain,
                        commcare_case_id: ^expected_commcare_case_id,
                        timestamp: ^timestamp,
                        reason: @reason
                      }}
    end

    test "fails silently when it receives invalid values for its arguments" do
      assert :error ==
               AnalyticsReporter.report_contacts_submission(
                 contacts_count: nil,
                 patient_case: nil,
                 timestamp: nil
               )
    end
  end

  describe "report_page_visit" do
    setup %{test: test} do
      self = self()

      :ok =
        :telemetry.attach_many(
          "#{test}",
          [
            [:share_my_contacts, :analytics, :page_visit]
          ],
          fn name, measurements, metadata, _ ->
            send(self, {:telemetry_event, name, measurements, metadata})
          end,
          nil
        )

      patient_case =
        "test/fixtures/commcare/case-with-test-results-and-contacts.json"
        |> File.read!()
        |> Jason.decode!()
        |> put_in(["properties", "smc_trigger_reason"], @reason)

      timestamp = DateTime.utc_now()

      {:ok, patient_case: patient_case, timestamp: timestamp}
    end

    test "emits a telemetry event with properties extracted from the patient case", %{
      patient_case: patient_case,
      timestamp: timestamp
    } do
      assert :ok ==
               AnalyticsReporter.report_page_visit(
                 page_identifier: @page,
                 patient_case: patient_case,
                 timestamp: timestamp
               )

      expected_external_id = patient_case |> PatientCase.external_id()
      expected_domain = patient_case |> PatientCase.domain()
      expected_commcare_case_id = patient_case |> PatientCase.case_id()

      assert_receive {:telemetry_event, [:share_my_contacts, :analytics, :page_visit], %{},
                      %{
                        page: @page,
                        external_id: ^expected_external_id,
                        domain: ^expected_domain,
                        commcare_case_id: ^expected_commcare_case_id,
                        timestamp: ^timestamp,
                        reason: @reason
                      }}
    end

    test "fails silently when it receives invalid values for its arguments" do
      assert :error ==
               AnalyticsReporter.report_page_visit(
                 page_identifier: nil,
                 patient_case: nil,
                 timestamp: nil
               )
    end
  end

  describe "report_unauthenticated_page_visit" do
    setup %{test: test} do
      self = self()

      :ok =
        :telemetry.attach_many(
          "#{test}",
          [
            [:share_my_contacts, :analytics, :unauthenticated_page_visit]
          ],
          fn name, measurements, metadata, _ ->
            send(self, {:telemetry_event, name, measurements, metadata})
          end,
          nil
        )

      timestamp = DateTime.utc_now()

      {:ok, timestamp: timestamp}
    end

    test "emits a telemetry event with the right page_identifier", %{
      timestamp: timestamp
    } do
      assert :ok ==
               AnalyticsReporter.report_unauthenticated_page_visit(
                 page_identifier: @page,
                 timestamp: timestamp,
                 locale: "en"
               )

      assert_receive {:telemetry_event, [:share_my_contacts, :analytics, :unauthenticated_page_visit], %{},
                      %{
                        page: @page,
                        timestamp: ^timestamp,
                        locale: "en"
                      }}
    end
  end

  describe "report_sms_triggered" do
    setup %{test: test} do
      self = self()

      :ok =
        :telemetry.attach_many(
          "#{test}",
          [
            [:share_my_contacts, :analytics, :sms_triggered]
          ],
          fn name, measurements, metadata, _ ->
            send(self, {:telemetry_event, name, measurements, metadata})
          end,
          nil
        )

      patient_case =
        "test/fixtures/commcare/case-with-test-results-and-contacts.json"
        |> File.read!()
        |> Jason.decode!()

      timestamp = DateTime.utc_now()

      {:ok, patient_case: patient_case, timestamp: timestamp}
    end

    test "emits a telemetry event with properties extracted from the patient case", %{
      patient_case: patient_case,
      timestamp: timestamp
    } do
      assert :ok ==
               AnalyticsReporter.report_sms_triggered(
                 patient_case: patient_case,
                 reason: @reason,
                 timestamp: timestamp
               )

      expected_external_id = patient_case |> PatientCase.external_id()
      expected_domain = patient_case |> PatientCase.domain()
      expected_commcare_case_id = patient_case |> PatientCase.case_id()

      assert_receive {:telemetry_event, [:share_my_contacts, :analytics, :sms_triggered], %{},
                      %{
                        external_id: ^expected_external_id,
                        domain: ^expected_domain,
                        commcare_case_id: ^expected_commcare_case_id,
                        reason: @reason,
                        timestamp: ^timestamp
                      }}
    end

    test "fails silently when it receives invalid values for its arguments" do
      assert :error ==
               AnalyticsReporter.report_sms_triggered(
                 patient_case: nil,
                 reason: nil,
                 timestamp: nil
               )
    end
  end
end
