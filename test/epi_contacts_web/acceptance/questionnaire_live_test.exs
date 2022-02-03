defmodule EpiContactsWeb.Acceptance.QuestionnaireLiveTest do
  use EpiContactsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import ExUnit.CaptureLog
  import Mox

  alias CommcareAPI.FakeCommcare
  alias EpiContacts.HTTPoisonMock
  alias EpiContacts.PostContactWorker
  alias Euclid.Test.Extra.Assertions

  # Data contained within test/fixtures/commcare/case-with-test-results-and-contacts.json
  @date_tested ~D[2020-11-01]
  @case_id "00000000-8434-4475-b111-bb3a902b398b"
  @domain "ny-state-covid19"
  @path "/start/#{@domain}/#{@case_id}"

  @non_symptomatic_end_date @date_tested |> Timex.shift(days: 3)
  @non_symptomatic_start_date @date_tested |> Timex.shift(days: -2)

  @house_contacts [["Bob", "Smith"], ["Minor Fred", "Smith"], ["Jane", "Smith"]]
  @social_contacts [["Rashida", "Jones"], ["Minor Mari", "Jones"]]
  @added_contacts [["Mo", "York"], ["Minor Khalid", "Jersey"]]

  setup :set_mox_global
  setup :verify_on_exit!

  setup do
    stub(
      AnalyticsReporterBehaviourMock,
      :report_page_visit,
      fn page_identifier: _page_identifier, patient_case: _patient_case, timestamp: _timestamp, locale: _ ->
        :ok
      end
    )

    :ok
  end

  describe "without locale set" do
    test "redirects to locale choice", %{conn: conn} do
      assert {:error, {:redirect, %{to: to}}} = live(conn, @path)

      %URI{path: path, query: query} = URI.new!(to)
      assert path == "/locale"

      expected = %{"redirect_to" => @path}
      assert URI.decode_query(query) == expected
    end
  end

  describe "when contacts are posted to CommCare" do
    setup %{conn: conn} do
      stub(CommcareClientBehaviourMock, :get_case, fn commcare_domain, case_id ->
        assert commcare_domain == @domain
        assert case_id == @case_id

        {:ok, patient_case_fixture()}
      end)

      conn =
        conn
        |> init_test_session(%{})
        |> fetch_session()
        |> put_session(:locale, "en")

      %{conn: conn}
    end

    test "shows confirm your identify form", %{conn: conn} do
      assert {:ok, _view, html} = live(conn, @path)
      assert html =~ "<h2>Confirm your identity</h2>"
    end

    test "shows error on invalid date of birth", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      assert confirm_identity_dob(view, "1961", "1", "1") =~ "is not correct"
    end

    test "accepts valid date of birth", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      refute confirm_identity_dob(view) =~ "is not correct"
    end

    test "results page shows 'Dear \#\{name\}'", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      assert render(view) =~ "Dear Test JME3"
    end

    test "results page shows table cell with initials", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      assert element(view, "tbody td:first-child") |> render() =~ "F.T."
      assert element(view, "tbody td:last-child") |> render() =~ "4658"
    end

    test "prep page shows instructions", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      assert_prep_page(view)
    end

    test "user lands on house page", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      render_click_next_button(view)
      assert_house_page(view)
    end

    test "contacts may be added on house page", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      render_click_next_button(view)
      add_contacts(view, @house_contacts)
    end

    test "user lands on social page", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      render_click_next_button(view)
      add_contacts(view, @house_contacts)
      render_click_next_button(view)
      assert_social_page(view)
    end

    test "contacts may be added on social page", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      render_click_next_button(view)
      add_contacts(view, @house_contacts)
      render_click_next_button(view)
      add_contacts(view, @social_contacts)
    end

    test "user lands on review page", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      render_click_next_button(view)
      add_contacts(view, @house_contacts)
      render_click_next_button(view)
      add_contacts(view, @social_contacts)
      render_click_next_button(view)

      assert_view_element_render_matches(view, "h2", "Review your contacts")

      assert_view_element_render_matches(view, "#contact-4 .contact-name", "Bob Smith")
      assert_view_element_render_matches(view, "#contact-3 .contact-name", "Minor Fred Smith")
      assert_view_element_render_matches(view, "#contact-2 .contact-name", "Jane Smith")
      assert_view_element_render_matches(view, "#contact-1 .contact-name", "Rashida Jones")
      assert_view_element_render_matches(view, "#contact-0 .contact-name", "Minor Mari Jones")
    end

    test "user may remove contacts on review page", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      render_click_next_button(view)
      add_contacts(view, @house_contacts)
      render_click_next_button(view)
      add_contacts(view, @social_contacts)
      render_click_next_button(view)

      element(view, "#delete-contact-4") |> render_click()
      element(view, "#delete-contact-1") |> render_click()

      assert view
             |> element("#contact-2 .contact-name")
             |> render() =~ "Minor Fred Smith"
      assert view
             |> element("#contact-1 .contact-name")
             |> render() =~ "Jane Smith"
      assert view
             |> element("#contact-0 .contact-name")
             |> render() =~ "Minor Mari Jones"

      refute view
             |> element("#contact-4")
             |> has_element?()
      refute view
             |> element("#contact-3")
             |> has_element?()
    end

    test "user may add new contacts after removing on review page", %{conn: conn} do
      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      render_click_next_button(view)
      add_contacts(view, @house_contacts)
      render_click_next_button(view)
      add_contacts(view, @social_contacts)
      render_click_next_button(view)

      element(view, "#delete-contact-4") |> render_click()
      element(view, "#delete-contact-1") |> render_click()

      add_contacts(view, @added_contacts)
      render_click_next_button(view)

      assert_view_element_render_matches(view, "h2", "Review your contacts")

      assert_view_element_render_matches(view, "#contact-4 .contact-name", "Minor Fred Smith")
      assert_view_element_render_matches(view, "#contact-3 .contact-name", "Jane Smith")
      assert_view_element_render_matches(view, "#contact-2 .contact-name", "Minor Mari Jones")
      assert_view_element_render_matches(view, "#contact-1 .contact-name", "Mo York")
      assert_view_element_render_matches(view, "#contact-0 .contact-name", "Minor Khalid Jersey")
    end

    test "user may agree and submit on review page", %{conn: conn} do
      FakeCommcare.start_link("test/fixtures/commcare/case-with-test-results-and-contacts.json")

      expect(AnalyticsReporterBehaviourMock, :report_contacts_submission, fn contacts_count: 5,
                                                                             patient_case: %{"case_id" => case_id},
                                                                             timestamp: timestamp ->
        assert case_id == @case_id
        Assertions.assert_datetime_approximate(DateTime.utc_now(), timestamp)

        :ok
      end)

      expect(HTTPoisonMock, :post, 5, fn url, body, header, _opts ->
        assert url == "https://www.commcarehq.org/a/ny-state-covid19/receiver/"
        assert body =~ "<?xml"
        assert header == [{:Authorization, "ApiKey johndoe@example.com:3923c69760a6f9e4f46a069c2691083010cbb57d"}]
        FakeCommcare.add_contact(body)

        {:ok,
         %HTTPoison.Response{status_code: 201, body: File.read!("test/fixtures/commcare/post-response_success.xml")}}
      end)

      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      render_click_next_button(view)
      add_contacts(view, @house_contacts)
      render_click_next_button(view)
      add_contacts(view, @social_contacts)
      render_click_next_button(view)

      element(view, "#delete-contact-4") |> render_click()
      element(view, "#delete-contact-1") |> render_click()

      add_contacts(view, @added_contacts)
      render_click_next_button(view)

      view
      |> form("#review", review: %{agree_to_share: true})
      |> render_submit()

      assert_view_element_render_matches(view, "h2", "Thank you for helping us stop the spread of COVID-19.")

      end_of_isolation_date =
        patient_case_fixture()
        |> EpiContactsWeb.PageView.formatted_release_from_isolation_date()

      assert_view_element_render_matches(view, "span.self-isolate-date", end_of_isolation_date)

      assert 5 == all_enqueued(worker: PostContactWorker) |> length()
      assert %{success: 5, failure: 0, snoozed: 0} ==
        Oban.drain_queue(queue: :default, with_safety: false)
    end
  end

  describe "when contacts are NOT posted to CommCare" do
    setup %{conn: conn} do
      stub(CommcareClientBehaviourMock, :get_case, fn commcare_domain, case_id ->
        assert commcare_domain == @domain
        assert case_id == @case_id

        {:ok, patient_case_fixture()}
      end)

      conn =
        conn
        |> init_test_session(%{})
        |> fetch_session()
        |> put_session(:locale, "en")

      %{conn: conn}
    end

    test "when a user answers 'no' to everything, nothing happens", %{conn: conn} do
      expect(AnalyticsReporterBehaviourMock, :report_contacts_submission, fn contacts_count: 0,
                                                                             patient_case: %{"case_id" => case_id},
                                                                             timestamp: timestamp ->
        assert case_id == @case_id
        Assertions.assert_datetime_approximate(DateTime.utc_now(), timestamp)

        :ok
      end)

      expect(HTTPoisonMock, :post, 0, fn _, _, _ -> nil end)

      assert {:ok, view, _html} = live(conn, @path)
      confirm_identity_dob(view)
      render_click_next_button(view)
      assert_prep_page(view)
      render_click_next_button(view)
      assert_house_page(view)
      element(view, "#back-button") |> render_click()
      assert_prep_page(view)
      render_click_next_button(view)
      assert_house_page(view)
      element(view, "#skip-button") |> render_click()
      assert_social_page(view)
      element(view, "#back-button") |> render_click()
      assert_house_page(view)
      element(view, "#skip-button") |> render_click()
      assert_social_page(view)
      element(view, "#skip-button") |> render_click()

      assert_view_element_render_matches(view, "h2", "Review your contacts")

      refute view
             |> element(".contacts .contact")
             |> has_element?()

      view
      |> form("#review", review: %{agree_to_share: true})
      |> render_submit()

      assert_view_element_render_matches(view, "h2", "Thank you for helping us stop the spread of COVID-19.")

      assert %{success: 0, failure: 0, snoozed: 0} ==
        Oban.drain_queue(queue: :default, with_safety: false)
    end
  end

  describe "when initial GET of data from CommCare fails" do
    setup %{conn: conn} do
      stub(CommcareClientBehaviourMock, :get_case, fn _, _ ->
        {:error, :not_found}
      end)

      conn =
        conn
        |> init_test_session(%{})
        |> fetch_session()
        |> put_session(:locale, "en")

      %{conn: conn}
    end

    test "user lands on error page if the initial GET to CommCare fails", %{conn: conn} do
      expect(HTTPoisonMock, :post, 0, fn _, _, _ -> nil end)

      log =
        capture_log(fn ->
          assert {:error, {:live_redirect, %{to: "/error"}}} = live(conn, @path)
        end)

      assert log =~ "case not found"
      assert %{success: 0, failure: 0, snoozed: 0} ==
        Oban.drain_queue(queue: :default, with_safety: false)
    end
  end

  # ---

  def render_click_next_button(view), do: element(view, "#next-button") |> render_click()

  def assert_view_element_render_matches(view, selector, match),
    do: assert view |> element(selector) |> render() =~ match

  def patient_case_fixture,
    do:
      "test/fixtures/commcare/case-with-test-results-and-contacts.json"
      |> File.read!()
      |> Jason.decode!()

  def patient_case_without_test_result_fixture,
    do:
      "test/fixtures/commcare/case-without-lab-result.json"
      |> File.read!()
      |> Jason.decode!()

  def confirm_identity_dob(view, year \\ "1987", month \\ "5", day \\ "5") do
    dob = %{year: year, month: month, day: day}

    view
    |> form("#confirm_identity", confirm_identity: %{dob: dob})
    |> render_submit()
  end

  def add_contacts(view, contacts_to_add) do
    exposed_on =
      patient_case_fixture()
      |> EpiContactsWeb.QuestionnaireView.exposed_on_select_options()
      |> Enum.reverse()
      |> hd()
      |> elem(1)
      |> Date.from_iso8601!()
      |> Timex.shift(days: -2)
      |> Date.to_iso8601()

    Enum.each(contacts_to_add, fn [first_name, last_name] ->
      element(view, "#add-contact-button") |> render_click()

      name = first_name <> " " <> last_name
      email = String.replace(first_name, " ", "") <> last_name <> "@example.com"
      phone =
        first_name |> to_charlist() |> hd() |> rem(10)
        |> then(fn i -> for _ <- 0..9, into: "", do: "#{i}" end)

      add_contact = %{
        first_name: first_name,
        last_name: last_name,
        email: email,
        phone: phone,
        exposed_on: exposed_on,
        relationship: "friend",
        contact_location: "workplace",
        primary_language: "en"
      }

      view
      |> form("#add_contact", contact: add_contact)
      |> render_submit()

      assert_view_element_render_matches(view, ".contacts .contact:first-child .contact-name", name)
      assert_view_element_render_matches(view, ".contacts .contact:first-child .contact-phone", phone)
      assert_view_element_render_matches(view, ".contacts .contact:first-child .contact-email", email)
    end)
  end

  def assert_house_page(view) do
    assert_view_element_render_matches(view, ".question", "Question 1 of 2")
    assert_view_element_render_matches(view, "h1", "Who has been in your house with you from")
  end

  def assert_prep_page(view) do
    assert_view_element_render_matches(view, "h2",
      "Now, you&#39;ll be asked to add contacts you&#39;ve seen from")
  end

  def assert_social_page(view) do
    start_date = @non_symptomatic_start_date |> Timex.lformat!("{WDfull}, {Mfull} {D}", "en")
    end_date = @non_symptomatic_end_date |> Timex.lformat!("{WDfull}, {Mfull} {D}", "en")

    assert_view_element_render_matches(view, ".question", "Question 2 of 2")
    assert_view_element_render_matches(view, "[data-tid=start-date]", start_date)
    assert_view_element_render_matches(view, "[data-tid=end-date]", end_date)
    assert_view_element_render_matches(view, "h1", "Who else did you see")
  end
end
