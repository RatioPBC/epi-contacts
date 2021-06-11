defmodule EpiContacts.ContactsTest do
  use EpiContacts.DataCase, async: true

  import Mox

  alias EpiContacts.Contact
  alias EpiContacts.Contacts
  alias EpiContacts.PostContactWorker

  setup :verify_on_exit!

  @test_case_id "00000000-8434-4475-b111-bb3a902b398b"

  describe "submitting contacts" do
    setup do
      stub(AnalyticsReporterBehaviourMock, :report_contacts_submission, fn contacts_count: _contacts_count,
                                                                           patient_case: _patient_case,
                                                                           timestamp: _timestamp ->
        :ok
      end)

      contacts = [%Contact{first_name: "Bob"}, %Contact{first_name: "Jane"}]

      patient_case =
        "test/fixtures/commcare/case-with-test-results-and-contacts.json"
        |> File.read!()
        |> Jason.decode!()

      [contacts: contacts, patient_case: patient_case]
    end

    test "enqueues a job to post the contacts to commcare", %{contacts: contacts, patient_case: patient_case} do
      Contacts.submit_contacts(contacts, patient_case)

      # all_enqueued returns jobs most recently inserted first
      assert [
               %{
                 args: %{
                   "contact" => %{"first_name" => "Bob"},
                   "patient_case" => patient_case
                 }
               },
               %{
                 args: %{
                   "contact" => %{"first_name" => "Jane"},
                   "patient_case" => patient_case
                 }
               }
             ] = all_enqueued(worker: PostContactWorker) |> Enum.reverse()
    end

    test "reports a metric that contacts have been submitted", %{contacts: contacts, patient_case: patient_case} do
      expect(AnalyticsReporterBehaviourMock, :report_contacts_submission, 1, fn contacts_count: contacts_count,
                                                                                patient_case: patient_case,
                                                                                timestamp: timestamp ->
        assert contacts_count == 2
        assert patient_case["case_id"] == @test_case_id
        assert DateTime.diff(timestamp, DateTime.utc_now()) < 2
        :ok
      end)

      Contacts.submit_contacts(contacts, patient_case)
    end
  end
end
