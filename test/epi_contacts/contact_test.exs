defmodule EpiContacts.ContactTest do
  use ExUnit.Case, async: true

  alias EpiContacts.Contact

  describe "required fields" do
    test "exposed on" do
      contact = valid_contact()
      changeset = Contact.change(contact, %{exposed_on: nil})
      assert changeset.errors[:exposed_on] == {"can't be blank", [validation: :required]}

      contact = valid_contact()
      changeset = Contact.change(contact, %{exposed_on: ~D[2020-11-09]})
      refute changeset.errors[:exposed_on]

      patient_case = %{"properties" => %{"isolation_start_date" => "2020-11-04"}}

      contact = valid_contact()
      changeset = Contact.change(contact, %{exposed_on: ~D[2020-11-01]}, patient_case)
      assert changeset.errors[:exposed_on]

      contact = valid_contact()
      changeset = Contact.change(contact, %{exposed_on: ~D[2020-11-17]}, patient_case)
      assert changeset.errors[:exposed_on]
    end

    test "names" do
      contact = valid_contact()
      changeset = Contact.change(contact, %{first_name: nil, last_name: nil})
      refute changeset.valid?
      assert changeset.errors[:first_name] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:last_name] == {"can't be blank", [validation: :required]}

      changeset = Contact.change(valid_contact(), %{first_name: "Josef", last_name: "Smeef", phone: "2345678923"})
      assert changeset.valid?
      assert changeset |> Ecto.Changeset.apply_changes() |> Contact.full_name() == "Josef Smeef"
    end

    test "phone is required" do
      contact = %Contact{}
      changeset = Contact.change(contact, %{})
      refute changeset.valid?
      assert changeset.errors[:phone] == {"can't be blank", [validation: :required]}
    end
  end

  describe "email validation" do
    setup do
      [contact: valid_contact()]
    end

    test "shows an error for an invalid email format", %{contact: contact} do
      changeset = Contact.change(contact, %{email: "invalid email address"})
      refute changeset.valid?
      assert changeset.errors[:email] == {"invalid email format", [validation: :format]}
    end

    test "allows anything with an @ in the middle and a dot after the @ as a valid email", %{contact: contact} do
      changeset = Contact.change(contact, %{email: "foo.bar@baz.com"})
      assert changeset.valid?
    end

    test "shows an error if there is not dot after the @", %{contact: contact} do
      changeset = Contact.change(contact, %{email: "foo@"})
      refute changeset.valid?
      assert changeset.errors == [email: {"invalid email format", [validation: :format]}]
    end
  end

  describe "phone validation" do
    setup do
      [contact: valid_contact()]
    end

    test "does not allow alphabetic characters", %{contact: contact} do
      changeset = Contact.change(contact, %{phone: "abc"})
      refute changeset.valid?
      assert changeset.errors[:phone] == {"must be 10 digits, no special characters", [validation: :format]}
    end

    test "allows numbers, parentheses, spaces, and pluses", %{contact: contact} do
      changeset = Contact.change(contact, %{phone: "2234567890"})
      assert changeset.valid?
    end
  end

  describe "is_minor validation" do
    setup do
      [contact: valid_contact()]
    end

    test "allows boolean values", %{contact: contact} do
      changeset = Contact.change(contact, %{is_minor: "false"})
      assert changeset.valid?

      changeset = Contact.change(contact, %{is_minor: "true"})
      assert changeset.valid?
    end

    test "does not allow non-boolean values", %{contact: contact} do
      changeset = Contact.change(contact, %{is_minor: "bananas"})
      refute changeset.valid?
      assert changeset.errors[:is_minor] == {"is invalid", [{:type, :boolean}, {:validation, :cast}]}
    end
  end

  describe "contact location" do
    setup do
      [contact: valid_contact()]
    end

    test "sets to unknown when given nil", %{contact: contact} do
      changeset = Contact.change(contact, %{})
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :contact_location) == "unknown"
    end

    test "validates the value", %{contact: contact} do
      changeset = Contact.change(contact, %{contact_location: "zoo"})
      refute changeset.valid?
      assert match?({"is invalid", [validation: :inclusion, enum: _]}, changeset.errors[:contact_location])
    end
  end

  describe "primary language" do
    setup do
      [contact: valid_contact()]
    end

    test "sets to other when given nil", %{contact: contact} do
      changeset = Contact.change(contact, %{})
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :primary_language) == "other"
    end

    test "validates the value", %{contact: contact} do
      changeset = Contact.change(contact, %{primary_language: "wakandan"})
      refute changeset.valid?
      assert match?({"is invalid", [validation: :inclusion, enum: _]}, changeset.errors[:primary_language])
    end
  end

  describe "relationship" do
    setup do
      [contact: valid_contact()]
    end

    test "sets to na when given nil", %{contact: contact} do
      changeset = Contact.change(contact, %{})
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :relationship) == "na"
    end

    test "validates the value", %{contact: contact} do
      changeset = Contact.change(contact, %{relationship: "zoo"})
      refute changeset.valid?
      assert match?({"is invalid", [validation: :inclusion, enum: _]}, changeset.errors[:relationship])
    end
  end

  test "initials" do
    assert Contact.initials(%{valid_contact() | last_name: nil}) == "J.*."
    assert Contact.initials(%{valid_contact() | last_name: ""}) == "J.*."
    assert Contact.initials(valid_contact()) == "J.S."
    assert Contact.initials(%{valid_contact() | first_name: nil}) == "*.S."
  end

  def valid_contact,
    do: %Contact{
      first_name: "Joe",
      last_name: "Smith",
      email: "joe@example.com",
      phone: "123-456-7890",
      exposed_on: ~D[2020-11-03]
    }
end
