defmodule EpiContactsWeb.LayoutHelpersTest do
  use ExUnit.Case, async: false

  import EpiContactsWeb.LayoutHelpers

  describe "revision_month_and_year" do
    setup do
      existing_revised_epoch = Application.get_env(:epi_contacts, :revision_date_epoch_seconds)

      on_exit(fn ->
        Application.put_env(:epi_contacts, :revision_date_epoch_seconds, existing_revised_epoch)
      end)
    end

    test "says the full name of the month and year of the epoch provided" do
      Application.put_env(:epi_contacts, :revision_date_epoch_seconds, "1601918940")
      assert revision_month_and_year() == "October 2020"
      Application.put_env(:epi_contacts, :revision_date_epoch_seconds, "1601218940")
      refute revision_month_and_year() == "October 2020"
    end

    test "does something when epoch isn't provided" do
      Application.put_env(:epi_contacts, :revision_date_epoch_seconds, "")
      assert revision_month_and_year() == "Unknown"
    end

    # This test is pending until Bypass is updated to work with our version of plug cowboy, see:
    # https://github.com/PSPDFKit-labs/bypass/pull/101
    # and
    # https://github.com/getsentry/sentry-elixir#testing-with-sentry
    @tag :skip
    test "reports missing epoch to sentry" do
      #      bypass = Bypass.open()
      #
      #      Bypass.expect(bypass, fn conn ->
      #        {:ok, _body, conn} = Plug.Conn.read_body(conn)
      #        Plug.Conn.resp(conn, 200, ~s<{"id": "340"}>)
      #      end)
      #
      #      Application.put_env(:sentry, :dsn, "http://public:secret@localhost:#{bypass.port}/1")
      #      Application.put_env(:sentry, :send_result, :sync)
      #
      #      Application.put_env(:epi_contacts, :revision_date_epoch_seconds, "")
      #      revision_month_and_year()
    end
  end
end
