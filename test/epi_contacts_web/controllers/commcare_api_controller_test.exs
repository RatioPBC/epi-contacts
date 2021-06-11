defmodule EpiContactsWeb.CommcareApiControllerTest do
  use EpiContactsWeb.ConnCase, async: true

  describe "authenticated webhook" do
    test "enqueues the SMS trigger", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Basic " <> ("AzureDiamond:hunter2" |> Base.encode64()))
        |> post(
          Routes.commcare_api_path(@endpoint, :webhook),
          %{
            "domain" => "test_domain",
            "case_id" => "test_case_id",
            "properties" => %{}
          }
        )

      assert text_response(conn, 200) =~ "OK"
      assert_enqueued(worker: EpiContacts.CommcareSmsTrigger)
    end
  end
end
