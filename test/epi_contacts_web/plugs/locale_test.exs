defmodule EpiContactsWeb.Plugs.LocaleTest do
  use EpiContactsWeb.ConnCase

  alias EpiContactsWeb.Plugs.Locale, as: P
  alias EpiContactsWeb.Router.Helpers, as: Routes

  import Phoenix.ConnTest

  setup context do
    session = context[:session] || %{}
    path = Routes.page_path(context.conn, :privacy, foo: "bar")
    encoded_path = URI.encode_www_form(path)

    conn =
      :get
      |> build_conn(path)
      |> Plug.Test.init_test_session(session)

    [conn: conn, path: encoded_path]
  end

  test "redirects if locale is not set", %{conn: conn, path: path} do
    conn = P.call(conn, P.init())

    assert redirected_to(conn) == "/locale?redirect_to=#{path}"
  end

  @tag session: %{locale: "not-supported"}
  test "redirects if locale is not supported", %{conn: conn, path: path} do
    conn = P.call(conn, P.init())

    assert redirected_to(conn) == "/locale?redirect_to=#{path}"
  end

  @tag session: %{locale: "es"}
  test "passes through if locale is set", %{conn: conn} do
    conn = P.call(conn, P.init())

    assert ["privacy"] = conn.path_info
    assert "foo=bar" = conn.query_string
    assert EpiContacts.Gettext.get_locale() == "es"
  end
end
