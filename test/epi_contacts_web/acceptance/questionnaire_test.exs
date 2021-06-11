defmodule EpiContactsWeb.Acceptance.QuestionnaireTest do
  use EpiContactsWeb.AcceptanceCase, async: false
  use Oban.Testing, repo: EpiContacts.Repo

  import Mox
  import ExUnit.CaptureLog

  alias CommcareAPI.FakeCommcare
  alias EpiContacts.HTTPoisonMock

  alias EpiContactsWeb.Assertions.{
    AddContact,
    Confirmation,
    ConfirmIdentity,
    ContactList,
    Error,
    House,
    Prep,
    Review,
    Social,
    TestResults
  }

  # Data contained within test/fixtures/commcare/case-with-test-results-and-contacts.json
  @date_tested ~D[2020-05-13]
  @dob ~D[1987-05-05]
  @name "Test JME3"
  @path "/start/ny-state-covid19/00000000-8434-4475-b111-bb3a902b398b"

  # User entered data (entered in the test):
  @incorrect_dob ~D[1961-01-01]

  # Expectations in the tests:
  @non_symptomatic_end_date @date_tested |> Timex.shift(days: 10)
  @non_symptomatic_start_date @date_tested |> Timex.shift(days: -2)

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    stub(AnalyticsReporterBehaviourMock, :report_unauthenticated_page_visit, fn page_identifier: _page_identifier,
                                                                                timestamp: _timestamp ->
      :ok
    end)

    :ok
  end

  describe "when contacts are posted to Commcare" do
    setup do
      FakeCommcare.start_link("test/fixtures/commcare/case-with-test-results-and-contacts.json")

      expect(HTTPoisonMock, :get, 6, fn url, header ->
        assert header == [{:Authorization, "ApiKey johndoe@example.com:0000000060a6f9e4f46a069c2691083010cbb57d"}]

        assert url ==
                 "https://www.commcarehq.org/a/ny-state-covid19/api/v0.5/case/00000000-8434-4475-b111-bb3a902b398b/?format=json&child_cases__full=true"

        {:ok, %HTTPoison.Response{status_code: 200, body: FakeCommcare.get_json()}}
      end)

      expect(HTTPoisonMock, :post, 5, fn url, body, header ->
        assert url == "https://www.commcarehq.org/a/ny-state-covid19/receiver/"
        assert body =~ "<?xml"
        assert header == [{:Authorization, "ApiKey johndoe@example.com:0000000060a6f9e4f46a069c2691083010cbb57d"}]
        FakeCommcare.add_contact(body)

        {:ok,
         %HTTPoison.Response{status_code: 201, body: File.read!("test/fixtures/commcare/post-response_success.xml")}}
      end)

      :ok
    end

    @tag :skip
    feature "'YES' PATH: a user can fill in the questionnaire - path with 'yes' answers for all questions", %{
      session: session
    } do
      session
      |> visit(@path)
      |> confirm_identity()
      |> test_results()
      |> prep()
      |> house(click: :add_contacts, contacts_to_add: [["Bob", "Smith"], ["Minor Fred", "Smith"], ["Jane", "Smith"]])
      |> social(click: :add_contacts, contacts_to_add: [["Rashida", "Jones"], ["Minor Mari", "Jones"]])
      |> review(
        click: :submit,
        expected_contacts: ["Bob Smith", "Minor Fred Smith", "Jane Smith", "Rashida Jones", "Minor Mari Jones"],
        contacts_to_delete: ["Bob Smith", "Rashida Jones"],
        contacts_to_add: [["Mo", "York"], ["Minor Khalid", "Jersey"]]
      )
      |> confirmation(end_date: end_date())

      assert 5 == all_enqueued(worker: PostContactWorker) |> length()
      assert %{success: 5, failure: 0} == Oban.drain_queue(queue: :default, with_safety: false)
    end
  end

  describe "when contacts are NOT posted to CommCare" do
    setup do
      FakeCommcare.start_link("test/fixtures/commcare/case-with-test-results-and-contacts.json")

      expect(HTTPoisonMock, :get, fn url, header ->
        assert header == [{:Authorization, "ApiKey johndoe@example.com:0000000060a6f9e4f46a069c2691083010cbb57d"}]

        assert url ==
                 "https://www.commcarehq.org/a/ny-state-covid19/api/v0.5/case/00000000-8434-4475-b111-bb3a902b398b/?format=json&child_cases__full=true"

        {:ok, %HTTPoison.Response{status_code: 200, body: FakeCommcare.get_json()}}
      end)

      expect(HTTPoisonMock, :post, 0, fn _, _, _ -> nil end)

      :ok
    end

    @tag :skip
    feature "'NO' PATH: a user can fill in the questionnaire - path with 'no' answers for all questions", %{
      session: session
    } do
      session
      |> visit(@path)
      |> confirm_identity()
      |> test_results()
      # ---
      |> prep()
      |> house(click: :back)
      |> prep()
      # ---
      |> house(click: :skip)
      |> social(click: :back)
      |> house(click: :skip)
      # ---
      |> social(click: :skip)
      |> review(click: :submit)
      |> confirmation(end_date: end_date())

      assert %{success: 0, failure: 0} == Oban.drain_queue(queue: :default, with_safety: false)
    end
  end

  describe "when initial GET of data from CommCare fails" do
    setup do
      expect(HTTPoisonMock, :get, 1, fn _url, _header ->
        {:ok, %HTTPoison.Response{status_code: 404}}
      end)

      expect(HTTPoisonMock, :post, 0, fn _, _, _ -> nil end)
      :ok
    end

    feature "an error page is shown if the initial GET to CommCare fails", %{session: session} do
      assert capture_log(fn ->
               session
               |> visit(@path)
               |> Error.assert_on_error_page()
             end) =~ "not found"

      assert %{success: 0, failure: 0} == Oban.drain_queue(queue: :default, with_safety: false)
    end
  end

  describe "when initial GET of data from CommCare does not have a test result" do
    setup do
      expect(HTTPoisonMock, :get, fn _url, _header ->
        json = File.read!("test/fixtures/commcare/case-without-lab-result.json")
        {:ok, %HTTPoison.Response{status_code: 200, body: json}}
      end)

      expect(HTTPoisonMock, :post, 0, fn _, _, _ -> nil end)
      :ok
    end

    @tag :skip
    feature "an error page is shown if the initial GET to CommCare does not return a lab result", %{session: session} do
      session
      |> visit(@path)
      |> Error.assert_on_error_page()

      assert %{success: 0, failure: 0} == Oban.drain_queue(queue: :default, with_safety: false)
    end
  end

  # ====================================================================================================================

  defp confirm_identity(session) do
    session
    |> ConfirmIdentity.assert_on_confirm_identity_page()
    |> ConfirmIdentity.fill_in_incorrect_dob_and_see_error(incorrect_dob: @incorrect_dob)
    |> ConfirmIdentity.fill_in_correct_dob(dob: @dob)
    |> click_button(:next)
  end

  defp test_results(session) do
    session
    |> TestResults.assert_on_test_results_page(name: @name)
    |> TestResults.assert_contact("F.T.", "4658")
    |> click_button(:next)
  end

  defp prep(session) do
    session
    |> Prep.assert_on_prep_page()
    |> click_button(:next)
  end

  defp house(session, click: :add_contacts, contacts_to_add: contacts_to_add) do
    session
    |> House.assert_on_house_page()
    |> AddContact.add_contacts(contacts_to_add: contacts_to_add)
    |> click_button(:add_contact)
    |> click_button(:next)
  end

  defp house(session, click: button_type) when button_type in [:skip, :back] do
    session
    |> House.assert_on_house_page()
    |> click_button(button_type)
  end

  defp social(session, click: :add_contacts, contacts_to_add: contacts_to_add) do
    session
    |> Social.assert_on_social_page(start_date: start_date(), end_date: end_date())
    |> AddContact.add_contacts(contacts_to_add: contacts_to_add)
    |> click_button(:add_contact)
    |> click_button(:next)
  end

  defp social(session, click: button_type) when button_type in [:skip, :back] do
    session
    |> Social.assert_on_social_page(start_date: start_date(), end_date: end_date())
    |> click_button(button_type)
  end

  defp review(session,
         click: :submit,
         expected_contacts: expected_contacts,
         contacts_to_delete: contacts_to_delete,
         contacts_to_add: contacts_to_add
       ) do
    after_deletion = expected_contacts -- contacts_to_delete
    after_deletion_and_addition = after_deletion ++ contacts_to_add

    session
    |> Review.assert_on_review_page()
    |> ContactList.assert_on_contact_list_page(expected_contacts: expected_contacts)
    |> ContactList.delete_contacts(contacts_to_delete: contacts_to_delete)
    |> ContactList.assert_on_contact_list_page(expected_contacts: after_deletion)
    |> AddContact.add_contacts(contacts_to_add: contacts_to_add)
    |> click_button(:next)
    |> ContactList.assert_on_contact_list_page(expected_contacts: after_deletion_and_addition)
    |> Review.assert_on_review_page()
    |> Review.check_i_agree_checkbox()
    |> click_button(:submit_to_commcare)
  end

  defp review(session, click: :submit) do
    session
    |> Review.assert_on_review_page()
    |> ContactList.assert_on_contact_list_page(expected_contacts: [])
    |> click_button(:submit_to_commcare)
    |> Review.assert_error_on_i_agree_checkbox()
    |> Review.check_i_agree_checkbox()
    |> click_button(:submit_to_commcare)
  end

  defp confirmation(session, end_date: end_date) do
    expected_end_of_isolation_date = end_date |> Timex.shift(days: 3)

    session
    |> Confirmation.assert_on_confirmation_page()
    |> Confirmation.assert_end_of_isolation_date_on_confirmation_page(expected_end_of_isolation_date)
  end

  def start_date, do: @non_symptomatic_start_date

  def end_date, do: @non_symptomatic_end_date
end
