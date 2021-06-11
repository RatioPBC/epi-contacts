defmodule EpiContactsWeb.Plugs.CommcareInfoLoaderTest do
  use EpiContactsWeb.ConnCase

  import EpiContacts.Testing.SecureId, only: [backdate_paseto: 2]

  alias EpiContactsWeb.Plugs.CommcareInfoLoader, as: P
  @case_id "123"
  @domain "abc"

  test "puts domain and case_id in session when passed in URL" do
    conn =
      :get
      |> build_conn("/foo", case_id: @case_id, commcare_domain: @domain)
      |> Plug.Test.init_test_session(%{})
      |> P.call(P.init())

    assert get_session(conn, :case_id) == @case_id
    assert get_session(conn, :domain) == @domain
  end

  test "puts domain and case id in session when passed valid secure ID" do
    secure_id = EpiContacts.SecureId.encode(%{c: @case_id, d: @domain})

    conn =
      :get
      |> build_conn("/foo", secure_id: secure_id)
      |> Plug.Test.init_test_session(%{})
      |> P.call(P.init())

    assert get_session(conn, :case_id) == @case_id
    assert get_session(conn, :domain) == @domain
  end

  test "redirects to expired page when secure ID is expired" do
    secure_id =
      50
      |> Timex.Duration.from_hours()
      |> backdate_paseto(data: %{"c" => @case_id, "d" => @domain})

    conn =
      :get
      |> build_conn("/foo", secure_id: secure_id)
      |> Plug.Test.init_test_session(%{})
      |> P.call(P.init())

    refute get_session(conn, :case_id)
    refute get_session(conn, :domain)
    assert conn.halted
    assert redirected_to(conn) == "/expired"
  end

  test "redirects to expired page when secure ID is invalid" do
    conn =
      :get
      |> build_conn("/foo", secure_id: "I'm not a secure ID")
      |> Plug.Test.init_test_session(%{})
      |> P.call(P.init())

    refute get_session(conn, :case_id)
    refute get_session(conn, :domain)
    assert conn.halted
    assert redirected_to(conn) == "/expired"
  end

  test "redirects to error when no params and no session" do
    conn =
      :get
      |> build_conn("/foo")
      |> Plug.Test.init_test_session(%{"foo" => "bar"})
      |> P.call(P.init())

    refute get_session(conn, :case_id)
    refute get_session(conn, :domain)
    refute get_session(conn, :foo)
    assert conn.halted
    assert redirected_to(conn) == "/error"
  end
end
