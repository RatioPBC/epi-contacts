defmodule EpiContacts.Contact do
  @moduledoc """
  Represents a contact that must be sent to commcare
  """

  use Ecto.Schema
  import Ecto.Changeset
  import EpiContacts.Validators
  alias EpiContacts.PatientCase

  @derive Jason.Encoder
  embedded_schema do
    field(:contact_id, :string)
    field(:email, :string)
    field(:is_minor, :boolean)
    field(:phone, :string)
    field(:first_name, :string)
    field(:last_name, :string)
    field(:contact_location, :string)
    field(:relationship, :string)
    field(:primary_language, :string)
    field(:exposed_on, :date)
  end

  def change(contact, attrs, patient_case \\ nil) do
    contact
    |> cast(attrs, [
      :phone,
      :email,
      :is_minor,
      :first_name,
      :last_name,
      :contact_location,
      :relationship,
      :primary_language,
      :exposed_on
    ])
    |> validate_required([:first_name, :last_name])
    |> validate_contact_location()
    |> validate_relationship()
    |> validate_primary_language()
    |> validate_exposure(patient_case)
    |> validate_required([:phone, :contact_location, :primary_language, :exposed_on])
    |> validate_email_format(:email)
    |> validate_phone_format(:phone)
  end

  def initials(contact) do
    first_initial =
      case first_name(contact) do
        nil -> "*"
        first_name -> String.first(first_name)
      end

    case last_name(contact) do
      nil -> first_initial <> ".*."
      last_name -> "#{first_initial}.#{String.first(last_name)}."
    end
  end

  def from_string_map(map) do
    %__MODULE__{
      contact_id: map["contact_id"],
      email: map["email"],
      is_minor: map["is_minor"],
      phone: map["phone"],
      exposed_on: PatientCase.parse_date(map["exposed_on"]),
      primary_language: map["primary_language"],
      first_name: map["first_name"],
      last_name: map["last_name"],
      contact_location: map["contact_location"],
      relationship: map["relationship"]
    }
  end

  def has_phone_number?(contact) do
    case contact.phone do
      "" -> false
      phone when is_binary(phone) -> true
      _ -> false
    end
  end

  def primary_language(contact), do: contact.primary_language
  def is_minor?(contact), do: contact.is_minor || false
  def phone(contact), do: contact.phone
  def full_name(contact), do: [first_name(contact), last_name(contact)] |> Enum.join(" ")
  def contact_id(contact), do: contact.contact_id
  def first_name(contact), do: contact.first_name
  def last_name(contact), do: Euclid.Exists.presence(contact.last_name)
  def relationship(contact), do: contact.relationship
  def contact_type(contact), do: contact.contact_location
  def email(contact), do: contact.email
  def exposed_on(contact), do: contact.exposed_on
end
