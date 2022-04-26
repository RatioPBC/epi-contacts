defmodule EpiContacts.CommcareSmsTriggerTest do
  use EpiContacts.DataCase, async: true
  use ExUnitProperties

  alias EpiContacts.{CommcareSmsTrigger, PatientCase}
  alias EpiContacts.Commcare
  alias EpiContacts.Parsers

  import Mox
  setup :verify_on_exit!

  @callout_property_name Commcare.PatientCase.callout_property_name()
  @sms_trigger_feature_flag CommcareSmsTrigger.sms_trigger_feature_flag()
  @pre_ci_feature_flag CommcareSmsTrigger.pre_ci_feature_flag()
  @pre_ci_surge_feature_flag CommcareSmsTrigger.pre_ci_surge_feature_flag()
  @minors_feature_flag CommcareSmsTrigger.minors_feature_flag()
  @id_property_name PatientCase.secure_id_property()
  @test_domain "test_domain"
  @test_case_id "test_case_id"

  @legit_properties %{
    "has_phone_number" => "yes",
    "dob_known" => "yes",
    "patient_type" => "anything_but_pui",
    "transfer_status" => "anything_but_sent_or_pending",
    "stub" => "is_not_yes",
    "current_status" => "is_not_closed",
    "smc_opt_in" => "yes",
    "dob" => "1980-01-01"
  }

  @manually_triggered_patient_case %{
    "domain" => @test_domain,
    "case_id" => @test_case_id,
    "properties" => @legit_properties
  }

  describe "case_meets_preconditions?/2" do
    setup do
      disable_sms_trigger_feature_flag()
      disable_pre_ci_feature_flag()
      enable_minors_feature_flag()

      [
        pre_ci_patient_case: %{
          "case_id" => @test_case_id,
          "domain" => @test_domain,
          "properties" => %{}
        },
        manually_triggered_patient_case: %{
          "case_id" => @test_case_id,
          "domain" => @test_domain,
          "properties" => %{
            "smc_opt_in" => "yes"
          }
        },
        transaction_id: "an-txn-id"
      ]
    end

    test "returns true when smc feature flag is enabled for the case domain and pre_ci feature flag is enabled for the case domain",
         %{
           pre_ci_patient_case: pre_ci_patient_case,
           manually_triggered_patient_case: manually_triggered_patient_case,
           transaction_id: transaction_id
         } do
      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      assert {true, :pre_ci} = CommcareSmsTrigger.case_meets_preconditions?(pre_ci_patient_case, transaction_id)

      assert {true, :post_ci} =
               CommcareSmsTrigger.case_meets_preconditions?(manually_triggered_patient_case, transaction_id)
    end

    test "returns true when smc feature flag is enabled for the case domain and pre_ci feature flag is disabled for the case domain and smc_opt_in property is set to yes",
         %{
           manually_triggered_patient_case: patient_case,
           transaction_id: transaction_id
         } do
      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      assert {true, :post_ci} = CommcareSmsTrigger.case_meets_preconditions?(patient_case, transaction_id)
    end

    test "returns true when smc feature flag is enabled for the case domain and the patient is a minor",
         %{
           pre_ci_patient_case: patient_case,
           transaction_id: transaction_id
         } do
      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      patient_case = put_in(patient_case, ["properties", "dob"], "2020-01-01")
      assert {true, :pre_ci_minor} = CommcareSmsTrigger.case_meets_preconditions?(patient_case, transaction_id)
    end

    test "returns false when smc feature flag is enabled for the case domain and pre_ci feature flag is disabled for the case domain and smc_opt_in property is not set to yes",
         %{
           pre_ci_patient_case: patient_case,
           transaction_id: transaction_id
         } do
      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      assert {false, _} = CommcareSmsTrigger.case_meets_preconditions?(patient_case, transaction_id)
    end

    test "returns false when smc feature flag is disabled for the case domain and pre_ci feature flag is enabled for the case domain",
         %{
           manually_triggered_patient_case: manually_triggered_patient_case,
           pre_ci_patient_case: pre_ci_patient_case,
           transaction_id: transaction_id
         } do
      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      assert {false, _} = CommcareSmsTrigger.case_meets_preconditions?(manually_triggered_patient_case, transaction_id)
      assert {false, _} = CommcareSmsTrigger.case_meets_preconditions?(pre_ci_patient_case, transaction_id)
    end

    test "returns false when smc feature flag is disabled for the case domain and pre_ci feature flag is disabled for the case domain",
         %{
           manually_triggered_patient_case: manually_triggered_patient_case,
           pre_ci_patient_case: pre_ci_patient_case,
           transaction_id: transaction_id
         } do
      assert {false, _} = CommcareSmsTrigger.case_meets_preconditions?(manually_triggered_patient_case, transaction_id)
      assert {false, _} = CommcareSmsTrigger.case_meets_preconditions?(pre_ci_patient_case, transaction_id)
    end

    test "returns false when minimum_age_feature_flag is disabled", %{
      pre_ci_patient_case: patient_case,
      transaction_id: transaction_id
    } do
      patient_case = put_in(patient_case, ["properties", "dob"], "2020-01-01")

      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      disable_minors_feature_flag()

      assert {false, :pre_ci_minor} = CommcareSmsTrigger.case_meets_preconditions?(patient_case, transaction_id)
    end
  end

  describe "case_meets_conditions?/3" do
    setup do
      FunWithFlags.enable(CommcareSmsTrigger.minimum_age_feature_flag())
      :ok
    end

    @failure_variants %{
      @id_property_name => ["any_value"],
      "has_phone_number" => ["no"],
      "dob_known" => ["no"],
      "patient_type" => ["pui"],
      "transfer_status" => ["pending", "sent"],
      "stub" => ["yes"],
      "current_status" => ["closed"],
      "dob" => [nil]
    }

    defp current_status, do: one_of([constant("open"), constant("closed")])
    defp patient_type, do: one_of([constant("confirmed"), constant("pui")])
    defp transfer_status, do: one_of([constant("approved"), constant("pending"), constant("sent")])
    defp yes_no, do: one_of([constant("yes"), constant("no")])

    defp dob do
      map({integer(1..12), integer(1..28)}, fn {month, day} ->
        1980
        |> Date.new!(month, day)
        |> Date.to_string()
      end)
    end

    property "always false with at least one failing condition" do
      check all(
              has_phone_number <- yes_no(),
              patient_type <- patient_type(),
              transfer_status <- transfer_status(),
              stub <- yes_no(),
              current_status <- current_status(),
              dob <- dob(),
              smc_id <- string(:ascii)
            ) do
        key_to_test = @failure_variants |> Map.keys() |> Enum.random()
        failure_value = @failure_variants |> Map.fetch!(key_to_test) |> Enum.random()

        properties =
          %{
            @id_property_name => smc_id,
            "has_phone_number" => has_phone_number,
            "patient_type" => patient_type,
            "transfer_status" => transfer_status,
            "stub" => stub,
            "current_status" => current_status,
            "dob" => dob
          }
          |> Map.put(key_to_test, failure_value)
          |> Map.put("key_to_test", key_to_test)
          |> Map.put("failure_value", failure_value)

        patient_case = Map.put(@manually_triggered_patient_case, "properties", properties)

        refute CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :pre_ci)
      end
    end

    test "returns true for case with properties that meet conditions" do
      assert CommcareSmsTrigger.case_meets_conditions?(@manually_triggered_patient_case, "transaction_id", :pre_ci)
    end

    test "returns false when the case is missing properties" do
      patient_case = %{"domain" => @test_domain, "case_id" => @test_case_id, "properties" => %{}}
      refute CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :pre_ci)
    end

    test "returns true when case is pre_ci and is less than 10 days old" do
      date_opened = "2020-04-18T18:38:55.406000Z"
      server_date_modified = "2020-04-27T18:38:55.406000Z"

      patient_case =
        @manually_triggered_patient_case
        |> put_in(["properties", "date_opened"], date_opened)
        |> Map.put("server_date_modified", server_date_modified)

      assert CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :pre_ci)
    end

    test "returns false when case is pre_ci and is 10 or more days old" do
      date_opened = "2020-04-18T18:38:55.406000Z"
      server_date_modified = "2020-04-29T18:38:55.406000Z"

      patient_case =
        @manually_triggered_patient_case
        |> put_in(["properties", "date_opened"], date_opened)
        |> Map.put("server_date_modified", server_date_modified)

      refute CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :pre_ci)
    end

    test "returns true when case is post_ci and is 10 or more days old" do
      date_opened = "2020-04-18T18:38:55.406000Z"
      server_date_modified = "2020-04-29T18:38:55.406000Z"

      patient_case =
        @manually_triggered_patient_case
        |> put_in(["properties", "date_opened"], date_opened)
        |> Map.put("server_date_modified", server_date_modified)

      assert CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :post_ci)
    end

    test "returns true when case is pre_ci and lacks a modified date" do
      date_opened = "2020-04-18T18:38:55.406000Z"

      patient_case =
        @manually_triggered_patient_case
        |> put_in(["properties", "date_opened"], date_opened)
        |> Map.delete("server_date_modified")

      assert CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :pre_ci)
    end

    test "returns true when case is pre_ci and has not been interviewed" do
      patient_case =
        @manually_triggered_patient_case
        |> put_in(["properties", "interview_disposition"], "")

      assert CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :pre_ci)
    end

    test "returns false when case is pre_ci and has been interviewed" do
      patient_case =
        @manually_triggered_patient_case
        |> put_in(["properties", "interview_disposition"], "invalid_phone_number")

      refute CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :pre_ci)
    end

    test "returns false when case is pre_ci and is missing the dob" do
      patient_case =
        @manually_triggered_patient_case
        |> put_in(["properties", "dob"], nil)

      refute CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :pre_ci)
    end

    test "returns true when case is post_ci and has been interviewed" do
      patient_case =
        @manually_triggered_patient_case
        |> put_in(["properties", "interview_disposition"], "invalid_phone_number")

      assert CommcareSmsTrigger.case_meets_conditions?(patient_case, "transaction_id", :post_ci)
    end

    test "returns true no matter what the patient case age is when post_ci" do
      assert CommcareSmsTrigger.case_meets_conditions?(@manually_triggered_patient_case, "transaction_id", :post_ci)
    end
  end

  describe "trigger_sms/3" do
    test "tells CommCare to update case properties when the decision is true" do
      transaction_id = "transaction_id"

      Mox.expect(CommcareClientBehaviourMock, :update_properties!, 1, fn domain, case_id, properties ->
        assert domain == @test_domain
        assert case_id == @test_case_id

        assert %{"c" => @test_case_id, "d" => @test_domain, "txn_id" => _} =
                 properties[@id_property_name]
                 |> EpiContacts.SecureId.decode!()
      end)

      CommcareSmsTrigger.trigger_sms(:pre_ci, @manually_triggered_patient_case, transaction_id)
    end

    test "does not send an update to CommCare when the decision is false" do
      transaction_id = "transaction_id"

      refute_property_update()

      assert {false, nil} =
               CommcareSmsTrigger.trigger_sms(
                 nil,
                 @manually_triggered_patient_case,
                 transaction_id
               )
    end
  end

  describe "perform/1" do
    setup do
      stub(AnalyticsReporterBehaviourMock, :report_sms_triggered, fn patient_case: _patient_case,
                                                                     reason: _reason,
                                                                     timestamp: _timestamp ->
        :ok
      end)

      stub(CommcareClientBehaviourMock, :update_properties!, fn _, _, _ -> :ok end)

      [
        pre_ci_patient_case: %{
          "case_id" => @test_case_id,
          "domain" => @test_domain,
          "properties" => %{}
        }
      ]
    end

    test "updates commcare when all required properties are set & feature flags allow case to be updated" do
      disable_sms_trigger_feature_flag()
      disable_pre_ci_feature_flag()

      assert_property_update()

      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))

      assert :ok == perform_trigger_job(@manually_triggered_patient_case)
    end

    test "does NOT update commcare when all required properties are set & feature flag is disabled" do
      refute_property_update()
      refute_analytics_event()

      disable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))

      assert {:discard, :not_triggered} = perform_trigger_job(@manually_triggered_patient_case)
    end

    test "does NOT update commcare when all required properties are set & minor feature flag is disabled" do
      patient_case = %{
        "case_id" => @test_case_id,
        "domain" => @test_domain,
        "properties" => %{"dob" => "2020-01-01"}
      }

      refute_property_update()
      refute_analytics_event()
      disable_minors_feature_flag()

      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))

      assert {:discard, "preconditions not met"} = perform_trigger_job(patient_case)
    end

    test "updates commcare case with property indicating a pre-ci sms trigger when all required properties are set & pre-ci is enabled & case is not manually triggered" do
      patient_case =
        @manually_triggered_patient_case
        |> put_in(["properties", "smc_opt_in"], "no")

      disable_sms_trigger_feature_flag()
      disable_pre_ci_feature_flag()

      assert_property_update(%{"smc_trigger_reason" => "pre_ci"})

      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))

      assert :ok == perform_trigger_job(patient_case)
    end

    test "updates commcare case with property indicating the sms trigger value when all required properties are set & case is manually triggered" do
      disable_sms_trigger_feature_flag()
      disable_pre_ci_feature_flag()

      assert_property_update(%{"smc_trigger_reason" => "post_ci"})

      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))

      assert :ok == perform_trigger_job(@manually_triggered_patient_case)
    end

    test "sends an analytics event that includes the sms trigger reason when all required properties are set & case is manually triggered" do
      disable_sms_trigger_feature_flag()
      disable_pre_ci_feature_flag()

      assert_analytics_event(reason: :post_ci)

      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))

      assert :ok == perform_trigger_job(@manually_triggered_patient_case)
    end

    test "oban job returns a success if creating the analytics event fails" do
      disable_sms_trigger_feature_flag()
      disable_pre_ci_feature_flag()

      mock_analytics_event_failure()

      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))

      assert :ok == perform_trigger_job(@manually_triggered_patient_case)
    end

    test "reports :pre_ci_surge when surge feature flag enabled", %{pre_ci_patient_case: pre_ci_patient_case} do
      patient_case =
        pre_ci_patient_case
        |> put_in(["properties", "dob"], "2000-01-01")
        |> put_in(["properties", "has_phone_number"], "yes")

      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_pre_ci_surge_feature_flag()
      assert_analytics_event(reason: :pre_ci_surge)

      assert :ok == perform_trigger_job(patient_case)

      disable_pre_ci_surge_feature_flag()
      assert_analytics_event(reason: :pre_ci)

      assert :ok == perform_trigger_job(patient_case)
    end

    def perform_trigger_job(params) do
      perform_job(CommcareSmsTrigger, CommcareSmsTrigger.prepare_args(params))
    end

    test "oban job returns error if commcare client update fails" do
      Mox.expect(CommcareClientBehaviourMock, :update_properties!, 1, fn _domain, _case_id, _properties ->
        {:error, "some error"}
      end)

      enable_sms_trigger_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))
      enable_pre_ci_feature_flag(for_actor: TestFunWithFlagsActor.new(@test_domain))

      assert {:error, "some error"} ==
               perform_trigger_job(@manually_triggered_patient_case)
    end

    test "enqueue inserts oban job" do
      job = CommcareSmsTrigger.enqueue!(%{"case_id" => @test_case_id, "domain" => @test_domain, "properties" => %{}})

      assert_enqueued(worker: CommcareSmsTrigger)

      assert %{
               "case_id" => @test_case_id,
               "domain" => @test_domain,
               "encrypted_patient_case" => _,
               "nonce" => _
             } = job.args
    end

    defp assert_property_update(additional_properties \\ %{}) do
      Mox.expect(CommcareClientBehaviourMock, :update_properties!, 1, fn domain, case_id, properties ->
        verify_property_update_request(domain, case_id, properties, additional_properties)
      end)
    end

    defp verify_property_update_request(domain, case_id, properties, additional_properties) do
      assert domain == @test_domain
      assert case_id == @test_case_id

      assert %{"c" => @test_case_id, "d" => @test_domain, "txn_id" => _} =
               properties[@id_property_name]
               |> EpiContacts.SecureId.decode!()

      assert properties[@callout_property_name] == true
      assert properties["contact_phone_number_is_verified"] == 1
      assert properties["smc_transaction_id"] |> Parsers.valid_uuid?()

      for {property_name, expected_value} <- additional_properties do
        assert(
          properties[property_name] == expected_value,
          "the property with name #{property_name |> Kernel.inspect()} does not have the expected value.\n" <>
            "expected: #{expected_value |> Kernel.inspect()}\n" <>
            "actual: #{properties[property_name] |> Kernel.inspect()}"
        )
      end

      :ok
    end

    def refute_property_update do
      Mox.expect(CommcareClientBehaviourMock, :update_properties!, 0, fn _, _, _ -> nil end)
    end

    defp mock_analytics_event_failure do
      expect(AnalyticsReporterBehaviourMock, :report_sms_triggered, 1, fn patient_case: _patient_case,
                                                                          reason: _reason,
                                                                          timestamp: _timestamp ->
        :error
      end)
    end

    defp assert_analytics_event(reason: expected_reason) do
      expect(AnalyticsReporterBehaviourMock, :report_sms_triggered, 1, fn patient_case: patient_case,
                                                                          reason: reason,
                                                                          timestamp: timestamp ->
        assert patient_case["case_id"] == @test_case_id
        assert reason == expected_reason
        assert DateTime.diff(timestamp, DateTime.utc_now()) < 2
        :ok
      end)
    end

    defp refute_analytics_event do
      expect(AnalyticsReporterBehaviourMock, :report_sms_triggered, 0, fn patient_case: _patient_case,
                                                                          timestamp: _timestamp ->
        :ok
      end)
    end
  end

  defp enable_sms_trigger_feature_flag(opts) do
    {:ok, true} = FunWithFlags.enable(@sms_trigger_feature_flag, opts)
  end

  defp disable_sms_trigger_feature_flag(opts \\ []) do
    {:ok, false} = FunWithFlags.disable(@sms_trigger_feature_flag, opts)
  end

  defp enable_pre_ci_feature_flag(opts) do
    {:ok, true} = FunWithFlags.enable(@pre_ci_feature_flag, opts)
  end

  defp disable_pre_ci_feature_flag do
    {:ok, false} = FunWithFlags.disable(@pre_ci_feature_flag, [])
  end

  defp enable_pre_ci_surge_feature_flag(opts \\ []) do
    {:ok, true} = FunWithFlags.enable(@pre_ci_surge_feature_flag, opts)
  end

  defp disable_pre_ci_surge_feature_flag do
    {:ok, false} = FunWithFlags.disable(@pre_ci_surge_feature_flag, [])
  end

  defp enable_minors_feature_flag do
    {:ok, true} = FunWithFlags.enable(@minors_feature_flag, [])
  end

  defp disable_minors_feature_flag do
    {:ok, false} = FunWithFlags.disable(@minors_feature_flag, [])
  end
end
