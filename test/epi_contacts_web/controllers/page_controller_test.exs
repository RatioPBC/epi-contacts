defmodule EpiContactsWeb.PageControllerTest do
  use EpiContactsWeb.ConnCase

  import Mox

  setup :verify_on_exit!

  @case_id "123"
  @domain "abc"

  setup do
    stub(AnalyticsReporterBehaviourMock, :report_unauthenticated_page_visit, fn page_identifier: _page_identifier,
                                                                                timestamp: _timestamp ->
      :ok
    end)

    :ok
  end

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ ">New York State Covid-19 Response"
  end

  test "GET /minor", %{conn: conn} do
    stub(CommcareClientBehaviourMock, :get_case, fn commcare_domain, case_id ->
      assert commcare_domain == @domain
      assert case_id == @case_id

      "test/fixtures/commcare/pre-ci-minor.json"
      |> File.read!()
      |> Jason.decode!()
      |> (fn json -> {:ok, json} end).()
    end)

    conn =
      conn
      |> Plug.Test.init_test_session(%{"case_id" => @case_id, "domain" => @domain})
      |> get("/minor")

    assert html_response(conn, 200) =~ "You should immediately tell your parent/guardian"
    assert html_response(conn, 200) =~ "Z.Z."
    assert html_response(conn, 200) =~ "2021-05-13"
  end

  test "GET /privacy", %{conn: conn} do
    conn = get(conn, "/privacy")
    assert html_response(conn, 200) =~ "Protecting Your Privacy"
  end

  describe "telemetry" do
    defp expect_page_visit_analytics(route) do
      expect(AnalyticsReporterBehaviourMock, :report_unauthenticated_page_visit, 1, fn page_identifier: page_identifier,
                                                                                       timestamp: timestamp ->
        assert page_identifier == route
        assert DateTime.diff(timestamp, DateTime.utc_now()) < 2
        :ok
      end)
    end

    test "sends a telemetry event when visiting the index page", %{conn: conn} do
      expect_page_visit_analytics(:index)
      get(conn, "/")
    end

    test "sends a telemetry event when visiting the error page", %{conn: conn} do
      expect_page_visit_analytics(:error)
      get(conn, "/error")
    end

    test "sends a telemetry event when visiting the link_expired page", %{conn: conn} do
      expect_page_visit_analytics(:link_expired)
      get(conn, "/expired")
    end

    test "sends a telemetry event when visiting the privacy page", %{conn: conn} do
      expect_page_visit_analytics(:privacy)
      get(conn, "/privacy")
    end

    test "sends a telemetry event when visiting the unable_to_verify page", %{conn: conn} do
      expect_page_visit_analytics(:unable_to_verify)
      get(conn, "/unable_to_verify")
    end
  end
end
