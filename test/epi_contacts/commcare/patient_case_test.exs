defmodule EpiContacts.Commcare.PatientCaseTest do
  use EpiContacts.Test.SimpleCase, async: true

  alias EpiContacts.SecureId
  alias EpiContacts.Commcare

  @test_domain "test_domain"
  @test_case_id "test_case_id"
  @test_transaction_id "test_transaction_id"
  @test_trigger_reason "pre_ci"

  @properties %{
    "has_phone_number" => "yes",
    "dob_known" => "yes",
    "patient_type" => "anything_but_pui",
    "transfer_status" => "anything_but_sent_or_pending",
    "stub" => "is_not_yes",
    "current_status" => "is_not_closed",
    "smc_opt_in" => "yes"
  }

  @patient_case %{
    "domain" => @test_domain,
    "case_id" => @test_case_id,
    "properties" => @properties
  }

  test "returns the domain and case id" do
    assert {@test_domain, @test_case_id, _} =
             Commcare.PatientCase.properties_for_update(@patient_case, @test_transaction_id, @test_trigger_reason)
  end

  describe "patient case properties" do
    test "sets the callout property to true" do
      {_, _, patient_case_properties} =
        Commcare.PatientCase.properties_for_update(@patient_case, @test_transaction_id, @test_trigger_reason)

      assert patient_case_properties[Commcare.PatientCase.callout_property_name()]
    end

    test "sets the contact phone number as verified" do
      {_, _, patient_case_properties} =
        Commcare.PatientCase.properties_for_update(@patient_case, @test_transaction_id, @test_trigger_reason)

      assert patient_case_properties["contact_phone_number_is_verified"] == 1
    end

    test "adds the transaction id and trigger reason" do
      {_, _, patient_case_properties} =
        Commcare.PatientCase.properties_for_update(@patient_case, @test_transaction_id, @test_trigger_reason)

      assert patient_case_properties["smc_transaction_id"] == @test_transaction_id
      assert patient_case_properties["smc_trigger_reason"] == @test_trigger_reason
    end

    test "adds the secure id" do
      {_, _, patient_case_properties} =
        Commcare.PatientCase.properties_for_update(@patient_case, @test_transaction_id, @test_trigger_reason)

      decoded_id = SecureId.decode!(patient_case_properties[EpiContacts.PatientCase.secure_id_property()])
      assert %{"c" => @test_case_id, "d" => @test_domain, "e" => _, "txn_id" => @test_transaction_id} = decoded_id
    end

    test "adds initials if they are missing" do
      patient_case =
        @patient_case
        |> put_in(["properties", "first_name"], "Zane")
        |> put_in(["properties", "last_name"], "Xavier")
        |> put_in(["properties", "initials"], nil)

      {_, _, patient_case_properties} =
        Commcare.PatientCase.properties_for_update(patient_case, @test_transaction_id, @test_trigger_reason)

      assert %{"initials" => "Z.X."} = patient_case_properties
    end

    test "does not include initials for update if they are already present on the patient case" do
      patient_case =
        @patient_case
        |> put_in(["properties", "first_name"], "Zane")
        |> put_in(["properties", "last_name"], "Xavier")
        |> put_in(["properties", "initials"], "X.Y.")

      {_, _, patient_case_properties} =
        Commcare.PatientCase.properties_for_update(patient_case, @test_transaction_id, @test_trigger_reason)

      refute Map.has_key?(patient_case_properties, "initials")
    end
  end
end
