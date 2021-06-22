defmodule EpiContacts.Validators do
  @moduledoc """
  Custom Ecto validators for phone number and email
  """

  alias EpiContacts.PatientCase
  import EpiContacts.Gettext
  import Ecto.Changeset

  # credo:disable-for-next-line
  @email_regex ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
  @phone_regex ~r/^[2-9]{1}[0-9]+$/

  def validate_email_format(changeset, fields) do
    validate_format(changeset, fields, @email_regex, message: dgettext_noop("errors", "invalid email format"))
  end

  def validate_phone_format(changeset, fields) do
    validate_format(changeset, fields, @phone_regex,
      message: dgettext_noop("errors", "must be 10 digits, no special characters")
    )
  end

  def validate_contact_location(changeset) do
    if changeset |> get_field(:contact_location) |> is_nil() do
      put_change(changeset, :contact_location, "unknown")
    else
      validate_inclusion(changeset, :contact_location, EpiContacts.Locations.locations())
    end
  end

  def validate_relationship(changeset) do
    if changeset |> get_field(:relationship) |> is_nil() do
      put_change(changeset, :relationship, "na")
    else
      validate_inclusion(changeset, :relationship, EpiContacts.Relationships.relationships())
    end
  end

  def validate_primary_language(changeset) do
    if changeset |> get_field(:primary_language) |> is_nil() do
      put_change(changeset, :primary_language, "other")
    else
      validate_inclusion(changeset, :primary_language, EpiContacts.Languages.languages())
    end
  end

  def validate_exposure(changeset, nil), do: changeset

  def validate_exposure(changeset, patient_case) do
    exposed_on = get_field(changeset, :exposed_on)
    start_of_infectious_period = PatientCase.start_of_infectious_period(patient_case)
    end_of_infectious_period = PatientCase.end_of_infectious_period(patient_case)

    in_range? =
      start_of_infectious_period
      |> Date.range(end_of_infectious_period)
      |> Enum.member?(exposed_on)

    if in_range? do
      changeset
    else
      add_error(changeset, :exposed_on, "outside of acceptable range")
    end
  end
end
