defmodule EpiContacts.PatientCaseTest do
  use ExUnit.Case, async: true

  alias EpiContacts.PatientCase
  alias Euclid.Extra.Random

  describe "initials/1" do
    test "returns initials from CommCare" do
      initials = "some-initials"

      patient_case = %{
        "properties" => %{
          "initials" => initials
        }
      }

      assert PatientCase.initials(patient_case) == initials
    end
  end

  describe "has_date_of_birth?/1" do
    setup context do
      patient_case = %{
        "properties" => %{
          "dob" => context.dob
        }
      }

      [patient_case: patient_case]
    end

    @tag dob: "2021-05-05"
    test "returns true when a valid dob is present", %{patient_case: patient_case} do
      assert PatientCase.has_date_of_birth?(patient_case)
    end

    @tag dob: "2021-13-42"
    test "returns false when dob is invalid", %{patient_case: patient_case} do
      refute PatientCase.has_date_of_birth?(patient_case)
    end

    @tag dob: nil
    test "returns false when dob is missing", %{patient_case: patient_case} do
      refute PatientCase.has_date_of_birth?(patient_case)
    end
  end

  describe "age/2" do
    setup context do
      now = DateTime.new!(~D[2021-05-05], ~T[12:00:00], "America/New_York")

      patient_case = %{
        "properties" => %{
          "dob" => context.dob
        }
      }

      [now: now, patient_case: patient_case]
    end

    @tag dob: "1981-05-04"
    test "just after the birthday", context do
      assert PatientCase.age(context.patient_case, context.now) == 40
    end

    @tag dob: "1981-05-05"
    test "on the birthday", context do
      assert PatientCase.age(context.patient_case, context.now) == 40
    end

    @tag dob: "1981-05-06"
    test "just before the birthday", context do
      assert PatientCase.age(context.patient_case, context.now) == 39
    end
  end

  describe "is_minor?/2" do
    setup context do
      now = DateTime.new!(~D[1999-05-05], ~T[12:00:00], "America/New_York")

      patient_case = %{
        "properties" => %{
          "dob" => context.dob
        }
      }

      [now: now, patient_case: patient_case]
    end

    @tag dob: "1981-05-04"
    test "just after the birthday", context do
      refute PatientCase.is_minor?(context.patient_case, context.now)
    end

    @tag dob: "1981-05-05"
    test "on the birthday", context do
      refute PatientCase.is_minor?(context.patient_case, context.now)
    end

    @tag dob: "1981-05-06"
    test "just before the birthday", context do
      assert PatientCase.is_minor?(context.patient_case, context.now)
    end
  end

  describe "start_of_infectious_period/1" do
    test "defaults to isolation_start_date" do
      patient_case = %{
        "properties" => %{
          "isolation_start_date" => "2020-12-21",
          "new_lab_result_specimen_collection_date" => "2020-12-22"
        }
      }

      assert ~D[2020-12-19] == PatientCase.start_of_infectious_period(patient_case)
    end

    test "falls back to new_lab_result_specimen_collection_date" do
      patient_case = %{
        "properties" => %{
          "isolation_start_date" => nil,
          "new_lab_result_specimen_collection_date" => "2020-12-22"
        }
      }

      assert ~D[2020-12-20] == PatientCase.start_of_infectious_period(patient_case)

      patient_case = %{
        "properties" => %{
          "new_lab_result_specimen_collection_date" => "2020-12-23"
        }
      }

      assert ~D[2020-12-21] == PatientCase.start_of_infectious_period(patient_case)
    end
  end

  describe "existing_contacts/1" do
    test "only returns contacts" do
      patient_case = %{
        "child_cases" => %{
          "1" => %{
            "properties" => %{
              "case_type" => "contact",
              "first_name" => "John",
              "last_name" => "Doe",
              "phone_home" => "8887776666"
            }
          },
          "2" => %{"properties" => %{"case_type" => "lab_result"}}
        }
      }

      assert [contact] = PatientCase.existing_contacts(patient_case)
      assert contact.first_name == "John"
      assert contact.last_name == "Doe"
      assert contact.phone == "8887776666"
    end
  end

  describe "smc_trigger_reason/1" do
    test "returns true when smc_trigger_reason is present" do
      patient_case = %{
        "properties" => %{
          "smc_trigger_reason" => "pre_ci"
        }
      }

      assert "pre_ci" == PatientCase.smc_trigger_reason(patient_case)
    end

    test "returns nil when smc_trigger_reason is absent" do
      patient_case_without_field = %{"properties" => %{}}

      assert nil == PatientCase.smc_trigger_reason(patient_case_without_field)
    end
  end

  describe "smc_opt_in?/1" do
    test "returns true when smc_opt_in is set to 'yes'" do
      patient_case = %{
        "properties" => %{
          "smc_opt_in" => "yes"
        }
      }

      assert PatientCase.smc_opt_in?(patient_case)
    end

    test "returns false when smc_opt_in is not set to 'yes'" do
      patient_case_without_field = %{"properties" => %{}}
      patient_case_with_field_set_to_no = %{"properties" => %{"smc_opt_in" => "no"}}
      patient_case_with_field_set_to_nil = %{"properties" => %{"smc_opt_in" => nil}}

      refute PatientCase.smc_opt_in?(patient_case_without_field)
      refute PatientCase.smc_opt_in?(patient_case_with_field_set_to_no)
      refute PatientCase.smc_opt_in?(patient_case_with_field_set_to_nil)
    end
  end

  describe "external_id/1" do
    test "returns the gid when the patient case has a domain and case id" do
      patient_case = %{
        "domain" => "ny-state-covid19",
        "case_id" => "case-123"
      }

      assert "gid://commcare/domain/ny-state-covid19/case/case-123" == PatientCase.external_id(patient_case)
    end

    test "returns nil when the patient case is malformed" do
      assert nil == PatientCase.external_id(nil)
      assert nil == PatientCase.external_id(%{})
      assert nil == PatientCase.external_id(%{"domain" => "ny-state-covid19"})
      assert nil == PatientCase.external_id(%{"case_id" => "case-123"})
    end
  end

  describe "days_between_open_and_modified/1" do
    test "returns the number of days from when the case was opened and when it was modified" do
      patient_case = %{
        "properties" => %{
          "date_opened" => "2020-04-18T18:38:55.406"
        },
        "server_date_modified" => "2020-04-27T18:38:55.406000Z"
      }

      assert PatientCase.days_between_open_and_modified(patient_case) == 9
    end

    test "when the case has not been modified" do
      patient_case = %{
        "properties" => %{
          "date_opened" => "2020-04-18T18:38:55.406000Z"
        }
      }

      assert PatientCase.days_between_open_and_modified(patient_case) == :error
    end
  end

  describe "interview_attempted_or_completed?/1" do
    test "returns false if interview_disposition is empty" do
      patient_case = %{
        "properties" => %{
          "interview_disposition" => ""
        }
      }

      refute PatientCase.interview_attempted_or_completed?(patient_case)
    end

    test "returns false if interview_disposition is missing" do
      patient_case = %{
        "properties" => %{}
      }

      refute PatientCase.interview_attempted_or_completed?(patient_case)
    end

    for interview_disposition <- [
          "invalid_phone_number",
          "agreed_to_participate",
          "deceased",
          "med_psych",
          "language_barrier",
          "incarcerated",
          "already_investigated",
          "facility_notification"
        ] do
      @tag interview_disposition: interview_disposition
      test "returns true if interview_disposition is #{interview_disposition}", %{
        interview_disposition: interview_disposition
      } do
        patient_case = %{
          "properties" => %{
            "interview_disposition" => interview_disposition
          }
        }

        assert PatientCase.interview_attempted_or_completed?(patient_case)
      end
    end
  end

  test "transaction_id/1" do
    txn_id = Random.string()

    patient_case = %{
      "properties" => %{
        "smc_transaction_id" => txn_id
      }
    }

    assert PatientCase.transaction_id(patient_case) == txn_id
  end
end
