defmodule EpiContactsWeb.EndpointTest do
  use EpiContactsWeb.ConnCase

  test "adds secure headers to responses", %{conn: conn} do
    conn =
      conn
      |> bypass_through()
      |> get("/")

    [cache_control] = get_resp_header(conn, "cache-control")
    [csp] = get_resp_header(conn, "content-security-policy")
    [sts] = get_resp_header(conn, "strict-transport-security")
    [xcto] = get_resp_header(conn, "x-content-type-options")

    assert cache_control == "private, no-store"
    assert csp =~ "default-src 'self'"
    assert sts =~ "max-age="
    assert xcto =~ "nosniff"
  end

  test "adds secure headers to static asset responses", %{conn: conn} do
    conn =
      conn
      |> bypass_through()
      |> get(Routes.static_path(@endpoint, "/js/app.js"))

    [sts] = get_resp_header(conn, "strict-transport-security")

    assert sts =~ "max-age="
  end
end
