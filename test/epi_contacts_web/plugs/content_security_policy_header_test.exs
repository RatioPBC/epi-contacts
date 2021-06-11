defmodule EpiContactsWeb.Plugs.ContentSecurityPolicyHeaderTest do
  use EpiContactsWeb.ConnCase

  alias EpiContactsWeb.Plugs.ContentSecurityPolicyHeader, as: P

  test "content-security-policy header value inlines necessary directives", %{conn: conn} do
    refute conn.private[:nonce]

    conn = conn |> P.call(P.init())

    nonce = conn.private[:nonce]
    assert nonce

    [csp] = get_resp_header(conn, "content-security-policy")
    assert csp =~ "connect-src 'self'"
    assert csp =~ "img-src 'self' 'nonce-#{nonce}' 'unsafe-inline'"
    assert csp =~ "style-src 'self' 'nonce-#{nonce}' 'unsafe-inline'"
    assert csp =~ "ws://"
    assert csp =~ "wss://"
    assert csp =~ "frame-ancestors 'none'"
  end

  test "content-security-policy header value does not include port number by default", %{conn: conn} do
    conn = conn |> P.call(P.init())

    [csp] = get_resp_header(conn, "content-security-policy")
    refute csp =~ ":4002"
  end

  test "content-security-policy header value can be overridden", %{conn: conn} do
    conn = conn |> P.call(P.init(header_override: "default-src: * 'unsafe-inline';"))

    [csp] = get_resp_header(conn, "content-security-policy")
    assert csp == "default-src: * 'unsafe-inline';"
  end
end
