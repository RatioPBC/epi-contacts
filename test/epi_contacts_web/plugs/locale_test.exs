defmodule EpiContactsWeb.Plugs.LocaleTest do
  use EpiContactsWeb.ConnCase

  alias EpiContactsWeb.Plugs.Locale, as: P
  alias EpiContactsWeb.Router.Helpers, as: Routes

  import Phoenix.ConnTest

  setup context do
    session = context[:session] || %{}
    conn =
      :get
      |> build_conn(Routes.page_path(context.conn, :privacy))
      |> Plug.Test.init_test_session(session)

    [conn: conn]
  end

  test "redirects if locale is not set", %{conn: conn} do
    conn = P.call(conn, P.init())

    assert redirected_to(conn) == "/locale"
  end

  @tag session: %{locale: "not-supported"}
  test "redirects if locale is not supported", %{conn: conn} do
    conn = P.call(conn, P.init())

    assert redirected_to(conn) == "/locale"
  end

  @tag session: %{locale: "es"}
  test "passes through if locale is set", %{conn: conn} do
    conn = P.call(conn, P.init())

    assert ["privacy"] = conn.path_info
  end
end
