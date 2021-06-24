defmodule EpiContactsWeb.Integrations.LocaleTest do
  use EpiContactsWeb.IntegrationCase

  test "prompts the user to select a language", %{conn: conn} do
    locale_page = Routes.page_path(conn, :locale)
    privacy_page = Routes.page_path(conn, :privacy)

    conn
    |> get(privacy_page)
    |> assert_response(redirect: locale_page)
    |> follow_redirect()
    |> assert_response(path: locale_page, html: "LOCALE PAGE!!!")
  end
end
