defmodule EpiContacts.ValidatorsTest do
  use EpiContacts.DataCase, async: true

  import Ecto.Changeset

  alias EpiContacts.{
    Contact,
    Languages,
    Locations,
    Relationships,
    Validators
  }

  describe "validate_contact_location/1" do
    test "puts unknown if absent" do
      assert_field_default(:validate_contact_location, :contact_location, "unknown")
    end

    test "adds error if it's an invalid value" do
      assert_error_with_invalid_option(:validate_contact_location, :contact_location, %{contact_location: "Portland"})
    end

    test "checks if it's a valid value" do
      assert_valid_value(:validate_contact_location, :contact_location, Locations)
    end
  end

  describe "validate_primary_language/1" do
    test "puts unknown if absent" do
      assert_field_default(:validate_primary_language, :primary_language, "other")
    end

    test "adds error if it's an invalid value" do
      assert_error_with_invalid_option(:validate_primary_language, :primary_language, %{
        primary_language: "Ancient Greek"
      })
    end

    test "checks if it's a valid value" do
      assert_valid_value(:validate_primary_language, :primary_language, Languages)
    end
  end

  describe "validate_relationship/1" do
    test "puts unknown if absent" do
      assert_field_default(:validate_relationship, :relationship, "na")
    end

    test "adds error if it's an invalid value" do
      assert_error_with_invalid_option(:validate_relationship, :relationship, %{relationship: "long lost cousin"})
    end

    test "checks if it's a valid value" do
      assert_valid_value(:validate_relationship, :relationship, Relationships)
    end
  end

  defp assert_valid_value(f, field, mod) do
    value = mod.values() |> Enum.take_random(1)
    changeset = Contact.changeset(%Contact{}, %{field => value})
    changeset = apply(Validators, f, [changeset])

    assert_no_errors_on(changeset, field)
  end

  defp assert_field_default(f, field, value) do
    changeset = Contact.changeset(%Contact{}, %{})
    changeset = apply(Validators, f, [changeset])
    assert get_field(changeset, field) == value
  end

  defp assert_error_with_invalid_option(f, field, attrs) do
    changeset = Contact.changeset(%Contact{}, attrs)
    changeset = apply(Validators, f, [changeset])

    refute changeset.valid?

    assert_errors_on(changeset, field)
  end

  defp assert_no_errors_on(%Ecto.Changeset{} = changeset, key) do
    !assert_errors_on(changeset, key)
  end

  defp assert_errors_on(%Ecto.Changeset{errors: errors}, key) do
    errors |> Keyword.keys() |> Enum.member?(key) |> assert()
  end
end
