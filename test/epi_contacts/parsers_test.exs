defmodule EpiContacts.ParsersTest do
  use ExUnit.Case, async: true

  alias EpiContacts.Parsers

  describe "valid_uuid?/1" do
    test "returns true for a valid UUID" do
      assert Parsers.valid_uuid?("00000000-ed9b-43e3-a11e-7ae9e32cc1e9")
    end

    test "returns false for a string that is not a valid UUID" do
      refute Parsers.valid_uuid?("70bbf8a4-ed9b-43e3-a11e-7ae9e32cc1e")
      refute Parsers.valid_uuid?("not-a-uuid")
    end
  end

  describe "datetime_with_or_without_zone/1" do
    test "converts to a datetime in UTC when the provided string is valid iso8601 with zone" do
      assert ~U[2020-04-27 18:38:55.406000Z] ==
               "2020-04-27T18:38:55.406000Z"
               |> Parsers.datetime_with_or_without_zone()
    end

    test "converts to a datetime in UTC when the provided string is valid iso8601 with offset" do
      assert ~U[2020-04-27 16:38:55.406000Z] ==
               "2020-04-27T18:38:55.406000+02"
               |> Parsers.datetime_with_or_without_zone()
    end

    test "converts to a datetime (interpreted as UTC) when the provided string is valid iso8601 without zone" do
      assert ~U[2020-04-27 18:38:55.406000Z] ==
               "2020-04-27T18:38:55.406000"
               |> Parsers.datetime_with_or_without_zone()
    end

    test "returns nil if no time is provided" do
      assert nil == Parsers.datetime_with_or_without_zone(nil)
    end

    test "returns nil if the format is invalid" do
      assert nil == Parsers.datetime_with_or_without_zone("20213-23-33 abc 1234")
    end
  end
end
