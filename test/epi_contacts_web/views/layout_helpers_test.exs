defmodule EpiContactsWeb.LayoutHelpersTest do
  use ExUnit.Case, async: false

  import EpiContacts.Gettext

  alias EpiContactsWeb.LayoutHelpers, as: H

  describe "revision_month_and_year" do
    setup context do
      if revision = context[:revision] do
        existing_revised_epoch = Application.get_env(:epi_contacts, :revision_date_epoch_seconds)
        Application.put_env(:epi_contacts, :revision_date_epoch_seconds, revision)

        on_exit(fn ->
          Application.put_env(:epi_contacts, :revision_date_epoch_seconds, existing_revised_epoch)
        end)
      end

      :ok
    end

    test "says the full name of the month and year of the epoch provided" do
      assert H.revision_month_and_year(revision: "1601918940") == "October 2020"
      assert H.revision_month_and_year(revision: 1_601_918_940) == "October 2020"
      assert H.revision_month_and_year(revision: "1601918940", locale: "es") == "Octubre 2020"
      assert H.revision_month_and_year(revision: 1_601_918_940, locale: "es") == "Octubre 2020"
      refute H.revision_month_and_year(revision: "1601218940") == "October 2020"
      refute H.revision_month_and_year(revision: 1_601_218_940) == "October 2020"
    end

    test "does something when epoch isn't provided" do
      assert H.revision_month_and_year(revision: nil) == "Unknown"

      assert H.revision_month_and_year(revision: nil, locale: "es") ==
               Gettext.with_locale("es", fn -> gettext("Unknown") end)
    end

    @tag revision: "1601918940"
    test "uses the value in the config" do
      assert H.revision_month_and_year() == "October 2020"
    end

    @tag revision: ""
    test "reports missing epoch to sentry" do
      bypass = Bypass.open()

      Bypass.expect(bypass, fn conn ->
        {:ok, _body, conn} = Plug.Conn.read_body(conn)
        Plug.Conn.resp(conn, 200, ~s<{"id": "340"}>)
      end)

      Application.put_env(:sentry, :dsn, "http://public:secret@localhost:#{bypass.port}/1")
      Application.put_env(:sentry, :included_environments, [:test])
      Application.get_all_env(:sentry)

      assert H.revision_month_and_year(sentry_result: :sync) == gettext("Unknown")
    end
  end
end
