defmodule EpiContactsWeb.QuestionnaireLiveTest do
  use EpiContactsWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Mox

  alias EpiContacts.{Questionnaire, Repo, SecureId, IdentityConfirmationSession}
  alias EpiContactsWeb.{ConfirmIdentityComponent, QuestionnaireLive}

  setup :verify_on_exit!

  @case_id "00000000-8434-4475-b111-bb3a902b398b"
  @domain "ny-state-covid19"

  setup %{conn: conn} do
    stub(AnalyticsReporterBehaviourMock, :report_page_visit, fn page_identifier: _page_identifier,
                                                                patient_case: _patient_case,
                                                                timestamp: _timestamp ->
      :ok
    end)

    conn =
      conn
      |> init_test_session(%{})
      |> fetch_session()
      |> put_session(:locale, "en")

    [conn: conn]
  end

  test "convert a component atom to a module" do
    assert QuestionnaireLive.to_module(:confirm_identity) == ConfirmIdentityComponent
  end

  describe "telemetry" do
    setup do
      stub(CommcareClientBehaviourMock, :get_case, fn commcare_domain, case_id ->
        assert commcare_domain == @domain
        assert case_id == @case_id

        "test/fixtures/commcare/case-with-test-results-and-contacts.json"
        |> File.read!()
        |> Jason.decode!()
        |> (fn json -> {:ok, json} end).()
      end)

      expect(AnalyticsReporterBehaviourMock, :report_page_visit, 1, fn page_identifier: page_identifier,
                                                                       patient_case: patient_case,
                                                                       timestamp: timestamp ->
        assert page_identifier == :confirm_identity
        assert patient_case["case_id"] == @case_id
        assert DateTime.diff(timestamp, DateTime.utc_now()) < 2
        :ok
      end)

      :ok
    end

    test "sends a telemetry event for a page visit based on the live action when the socket is connected", %{conn: conn} do
      assert {:ok, _view, _} = live(conn, "/start/ny-state-covid19/#{@case_id}")
    end
  end

  describe "pre-CI minor" do
    setup do
      stub(CommcareClientBehaviourMock, :get_case, fn commcare_domain, case_id ->
        assert commcare_domain == @domain
        assert case_id == @case_id

        "test/fixtures/commcare/pre-ci-minor.json"
        |> File.read!()
        |> Jason.decode!()
        |> (fn json -> {:ok, json} end).()
      end)

      :ok
    end

    test "redirects to the minor page", %{conn: conn} do
      secure_id = SecureId.encode(%{c: @case_id, d: @domain})
      conn = get(conn, "/s/#{secure_id}")
      assert {:error, {:live_redirect, %{flash: _, to: "/minor"}}} = live(conn)
    end
  end

  describe "confirm_identity_component" do
    setup do
      stub(CommcareClientBehaviourMock, :get_case, fn commcare_domain, case_id ->
        assert commcare_domain == @domain
        assert case_id == @case_id

        "test/fixtures/commcare/case-with-test-results-and-contacts.json"
        |> File.read!()
        |> Jason.decode!()
        |> (fn json -> {:ok, json} end).()
      end)

      :ok
    end

    test "using a secure id", %{conn: conn} do
      secure_id = SecureId.encode(%{c: @case_id, d: @domain})
      conn = get(conn, "/s/#{secure_id}")
      {:ok, questionnaire_live, disconnected_html} = live(conn)

      assert conn.assigns.patient_case
      assert disconnected_html =~ "Confirm your identity"

      connected_html = render(questionnaire_live)
      assert connected_html =~ "Confirm your identity"
    end

    test "it shows the pages title", %{conn: conn} do
      {:ok, questionnaire_live, disconnected_html} =
        live(conn, "/start/ny-state-covid19/00000000-8434-4475-b111-bb3a902b398b")

      assert disconnected_html =~ "Confirm your identity"

      connected_html = render(questionnaire_live)
      assert connected_html =~ "Confirm your identity"
    end

    test "it show validation errors when you simply click next", %{conn: conn} do
      {:ok, view, _} = live(conn, "/start/ny-state-covid19/00000000-8434-4475-b111-bb3a902b398b")

      submit_html = submit(view, %{"dob" => %{"year" => "", "month" => "", "day" => ""}})

      assert submit_html =~ "can&#39;t be blank"
    end

    test "it shows validation errors when the incorrect data is submitted", %{conn: conn} do
      {:ok, view, html} = live(conn, "/start/ny-state-covid19/00000000-8434-4475-b111-bb3a902b398b")

      refute html =~ "is not correct"

      submit_html = submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "01"}})

      assert submit_html =~ "is not correct"
    end

    test "it shows a lockout error when a user submits more than the limit", %{conn: conn} do
      {:ok, view, html} = live(conn, "/start/ny-state-covid19/00000000-8434-4475-b111-bb3a902b398b")
      lock_out_text = dgettext("errors", "locked out")

      refute html =~ lock_out_text

      refute submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "01"}}) =~ lock_out_text
      refute submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "02"}}) =~ lock_out_text
      refute submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "03"}}) =~ lock_out_text
      refute submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "04"}}) =~ lock_out_text
      refute submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "05"}}) =~ lock_out_text
      assert submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "06"}}) =~ lock_out_text
    end

    test "remains locked out after submitting six times, even if the seventh is successful", %{conn: conn} do
      {:ok, view, html} = live(conn, "/start/ny-state-covid19/00000000-8434-4475-b111-bb3a902b398b")
      lock_out_text = dgettext("errors", "locked out")

      refute html =~ lock_out_text

      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "01"}})
      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "02"}})
      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "03"}})
      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "04"}})
      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "05"}})
      # submit(view, %{"dob" => "1983-01-06"})
      assert submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "06"}}) =~ lock_out_text
      assert submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "07"}}) =~ lock_out_text

      # clear out the submission limit error message to prevent an assertion race condition
      {:ok, view, html} = live(conn, "/start/ny-state-covid19/00000000-8434-4475-b111-bb3a902b398b")
      refute html =~ lock_out_text

      submit_html = submit(view, %{"dob" => "1987-05-05"})

      assert submit_html =~ lock_out_text
    end

    test "does not show locked out text once lock out has expired", %{conn: conn} do
      external_id = "gid://commcare/domain/#{@domain}/case/#{@case_id}"
      lock_out_text = dgettext("errors", "locked out")
      {:ok, view, _} = live(conn, "/start/ny-state-covid19/00000000-8434-4475-b111-bb3a902b398b")

      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "01"}})
      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "02"}})
      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "03"}})
      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "04"}})
      submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "05"}})
      html = submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "01"}})

      assert html =~ lock_out_text
      refute html =~ "is not correct"

      session = Repo.get_by(IdentityConfirmationSession, external_id: external_id)

      {:ok, _} =
        Questionnaire.change_identity_confirmation_session(session, %{unlocked_at: DateTime.utc_now()}) |> Repo.update()

      refute submit(view, %{"dob" => %{"year" => "1983", "month" => "1", "day" => "01"}}) =~ lock_out_text
    end

    defp submit(view, options) do
      view
      |> element("#confirm_identity")
      |> render_submit(%{
        "confirm_identity" => options
      })
    end
  end

  describe "adding a contact" do
    setup do
      stub(CommcareClientBehaviourMock, :get_case, fn commcare_domain, case_id ->
        assert commcare_domain == @domain
        assert case_id == @case_id

        "test/fixtures/commcare/case-with-test-results-and-contacts.json"
        |> File.read!()
        |> Jason.decode!()
        |> (fn json -> {:ok, json} end).()
      end)

      :ok
    end

    test "it shows a validation error when the user omits when they most recently saw a contact", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/start/ny-state-covid19/00000000-8434-4475-b111-bb3a902b398b")

      view
      |> form("#confirm_identity", %{
        "confirm_identity" => %{"dob" => %{"year" => "1987", "month" => "5", "day" => "5"}}
      })
      |> render_submit()

      view
      |> element("#next-button")
      |> render_click()

      view
      |> element("#next-button")
      |> render_click()

      view
      |> element("#add-contact-button")
      |> render_click()

      html =
        view
        |> form("#add_contact", %{"contact" => %{}})
        |> render_submit()

      assert html =~ "outside of acceptable range"
    end
  end
end
