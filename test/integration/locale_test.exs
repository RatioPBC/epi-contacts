defmodule EpiContactsWeb.Integrations.LocaleTest do
  use EpiContactsWeb.IntegrationCase
  import Mox

  test "prompts the user to select a language", %{conn: conn} do
    locale_path = Routes.page_path(conn, :locale)
    privacy_path = Routes.page_path(conn, :privacy, foo: "bar")
    locale_redirect = "#{locale_path}?redirect_to=%2Fprivacy%3Ffoo%3Dbar"
    continue_in_english = Gettext.with_locale("en", fn -> gettext("Continue in language...") end)
    continue_in_spanish = Gettext.with_locale("es", fn -> gettext("Continue in language...") end)
    header_in_english = Gettext.with_locale("en", fn -> dgettext("privacy_policy", "Protecting Your Privacy") end)
    header_in_spanish = Gettext.with_locale("es", fn -> dgettext("privacy_policy", "Protecting Your Privacy") end)

    expect(
      AnalyticsReporterBehaviourMock,
      :report_unauthenticated_page_visit,
      # once for English, once for Spanish
      2,
      fn page_identifier: :privacy, timestamp: _timestamp ->
        :ok
      end
    )

    locale_conn =
      conn
      |> get(privacy_path)
      |> assert_response(redirect: locale_redirect)
      |> follow_redirect()
      |> assert_response(path: locale_path, html: privacy_path)
      |> assert_response(html: continue_in_english)
      |> assert_response(html: continue_in_spanish)

    locale_conn
    |> follow_form(%{}, identifier: "#locale-picker-en")
    |> assert_response(html: header_in_english)

    locale_conn
    |> follow_form(%{}, identifier: "#locale-picker-es")
    |> assert_response(html: header_in_spanish)
  end

  describe "LocaleForm" do
    alias EpiContactsWeb.PageController.LocaleForm

    test "changeset/1", %{conn: conn} do
      privacy_path = Routes.page_path(conn, :privacy, foo: "bar")
      locale_path = Routes.page_path(conn, :locale, redirect_to: privacy_path)

      conn = build_conn(:get, locale_path)
      %Plug.Conn{params: params} = fetch_query_params(conn)

      assert %Ecto.Changeset{} = changeset = LocaleForm.changeset(params)
      refute Ecto.Changeset.get_field(changeset, :locale)
      assert Ecto.Changeset.get_field(changeset, :redirect_to) == privacy_path
      refute changeset.valid?

      params = Map.put(params, "locale", "en")

      assert %Ecto.Changeset{} = changeset = LocaleForm.changeset(params)
      assert Ecto.Changeset.get_field(changeset, :locale) == "en"
      assert Ecto.Changeset.get_field(changeset, :redirect_to) == privacy_path
      assert changeset.valid?
    end
  end
end
