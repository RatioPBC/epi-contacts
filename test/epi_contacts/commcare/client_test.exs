defmodule EpiContacts.Commcare.ClientTest do
  use EpiContacts.DataCase, async: true

  alias EpiContacts.Commcare.Client, as: CommcareClient
  alias EpiContacts.Parsers
  alias EpiContacts.Test

  import Mox
  setup :verify_on_exit!

  @test_domain "test domain"
  @test_case_id "test case id"

  test "update_properties!" do
    envelope_id = Ecto.UUID.generate()
    envelope_timestamp = DateTime.utc_now()
    opts = [envelope_id: envelope_id, envelope_timestamp: envelope_timestamp]

    Mox.expect(EpiContacts.HTTPoisonMock, :post, 1, fn url, body, _headers, _opt ->
      assert url == "https://www.commcarehq.org/a/#{@test_domain}/receiver/"
      assert body == CommcareClient.build_update(@test_case_id, %{some: "property"}, opts)
      {:ok, %{status_code: 201, body: ""}}
    end)

    CommcareClient.update_properties!(@test_domain, @test_case_id, %{some: "property"}, opts)
  end

  test "build_update" do
    envelope_id = Ecto.UUID.generate()
    envelope_timestamp = DateTime.utc_now()
    opts = [envelope_id: envelope_id, envelope_timestamp: envelope_timestamp]

    assert CommcareClient.build_update(@test_case_id, %{some: "property", other: "value"}, opts) == """
           <?xml version="1.0" encoding="UTF-8"?>\
           <data xmlns="http://dev.commcarehq.org/jr/xforms">\
           <case case_id="test case id" user_id="abc123" xmlns="http://commcarehq.org/case/transaction/v2">\
           <update>\
           <other>value</other>\
           <some>property</some>\
           </update>\
           </case>\
           <n1:meta xmlns:n1=\"http://openrosa.org/jr/xforms\"><n1:deviceID>Formplayer</n1:deviceID><n1:timeStart>#{
             envelope_timestamp
           }</n1:timeStart><n1:timeEnd>#{envelope_timestamp}</n1:timeEnd><n1:username>geometer_user_1</n1:username><n1:userID>abc123</n1:userID><n1:instanceID>#{
             envelope_id
           }</n1:instanceID></n1:meta>\
           </data>\
           """

    assert CommcareClient.build_update(@test_case_id, [kwlist: "also works"], opts) == """
           <?xml version="1.0" encoding="UTF-8"?>\
           <data xmlns="http://dev.commcarehq.org/jr/xforms">\
           <case case_id="test case id" user_id="abc123" xmlns="http://commcarehq.org/case/transaction/v2">\
           <update>\
           <kwlist>also works</kwlist>\
           </update>\
           </case>\
           <n1:meta xmlns:n1=\"http://openrosa.org/jr/xforms\"><n1:deviceID>Formplayer</n1:deviceID><n1:timeStart>#{
             envelope_timestamp
           }</n1:timeStart><n1:timeEnd>#{envelope_timestamp}</n1:timeEnd><n1:username>geometer_user_1</n1:username><n1:userID>abc123</n1:userID><n1:instanceID>#{
             envelope_id
           }</n1:instanceID></n1:meta>\
           </data>\
           """
  end

  describe "build_contact" do
    setup do
      {:ok, true} = FunWithFlags.enable(:feb_17_commcare_release, [])
      now_as_string = "2021-08-16 01:02:03Z"
      {:ok, now, _} = DateTime.from_iso8601(now_as_string)

      patient_case = %{
        "domain" => "ny-state-covid19",
        "case_id" => "case-123",
        "properties" => %{
          "owner_id" => "owner-id",
          "doh_mpi_id" => "patient-doh-mpi-id",
          "smc_trigger_reason" => "pre_ci"
        }
      }

      contact = %{
        first_name: "Joe",
        last_name: "Smith",
        email: "joe@example.com",
        phone: "123-456-7890",
        exposed_on: ~D[2020-11-03],
        contact_id: "1111",
        is_minor: false,
        relationship: "family",
        contact_location: "household",
        primary_language: "en"
      }

      envelope_id = Ecto.UUID.generate()

      xml = CommcareClient.build_contact(patient_case, contact, envelope_id: envelope_id, envelope_timestamp: now)

      doc = xml |> Floki.parse_document!()

      [xml: xml, doc: doc, now: now_as_string, envelope_id: envelope_id]
    end

    test "xml has <?xml> element", %{xml: xml} do
      assert xml |> String.starts_with?(~s|<?xml version=\"1.0\" encoding=\"UTF-8\"?>|)
    end

    test "xml contains base data", %{doc: doc} do
      assert Test.Xml.attr(doc, "data", "xmlns") == "http://dev.commcarehq.org/jr/xforms"
      assert Test.Xml.attr(doc, "case:nth-of-type(1)", "xmlns") == "http://commcarehq.org/case/transaction/v2"
      assert Test.Xml.attr(doc, "case:nth-of-type(1)", "case_id") |> Parsers.valid_uuid?()
      # expected value of user_id comes from COMMCARE_USER_ID from .env.test
      assert Test.Xml.attr(doc, "case:nth-of-type(1)", "user_id") == "abc123"
      assert Test.Xml.text(doc, "case:nth-of-type(1) create case_name") == "Joe Smith"
      assert Test.Xml.text(doc, "case:nth-of-type(1) create case_type") == "contact"
    end

    test "xml index field contains info about the parent case", %{doc: doc} do
      assert Test.Xml.attr(doc, "case:nth-of-type(1) index parent", "case_type") == "patient"
      assert Test.Xml.attr(doc, "case:nth-of-type(1) index parent", "relationship") == "extension"
    end

    test "xml contains metadata", %{doc: doc, now: now, envelope_id: envelope_id} do
      assert Test.Xml.attr(doc, "meta", "xmlns:n1") == "http://openrosa.org/jr/xforms"
      assert Test.Xml.text(doc, "meta timeStart") == now
      assert Test.Xml.text(doc, "meta timeEnd") == now
      assert Test.Xml.text(doc, "meta username") == "geometer_user_1"
      assert Test.Xml.text(doc, "meta userID") == "abc123"
      assert Test.Xml.text(doc, "meta instanceID") == envelope_id
    end

    test "xml update field contains contact data", %{doc: doc} do
      expected_fields = %{
        "commcare_email_address" => "joe@example.com",
        "contact_id" => "1111",
        "contact_is_a_minor" => "no",
        "contact_status" => "pending_first_contact",
        "contact_type" => "household",
        "elicited_from_smc" => "yes",
        "exposure_date" => "2020-11-3",
        "first_name" => "Joe",
        "full_name" => "Joe Smith",
        "fup_end_date" => "2020-11-17",
        "fup_next_method" => "call",
        "fup_next_type" => "initial_interview",
        "fup_start_date" => "2020-11-3",
        "has_index_case" => "yes",
        "has_phone_number" => "yes",
        "initials" => "J.S.",
        "investigation" => "",
        "investigation_case_id" => "",
        "investigation_id" => "",
        "investigation_name" => "",
        "index_case_id" => "patient-doh-mpi-id",
        "last_name" => "Smith",
        "name" => "Joe Smith",
        "owner_id" => "owner-id",
        "phone_home" => "123-456-7890",
        "primary_language" => "en",
        "relation_to_case" => "family",
        "smc_trigger_reason" => "pre_ci"
      }

      Floki.find(doc, "case:nth-of-type(1) update *")
      |> Enum.map(fn
        {element, _attrs, [value]} -> {element, value}
        {element, _attrs, []} -> {element, ""}
      end)
      |> Map.new()
      |> assert_eq(
        expected_fields,
        only: expected_fields |> Map.keys()
      )
    end
  end
end
