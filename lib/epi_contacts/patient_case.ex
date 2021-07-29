defmodule EpiContacts.PatientCase do
  alias EpiContacts.Contact
  alias EpiContacts.Parsers

  @moduledoc """
  utilities for working with patient case map data
  """
  @minimum_age 18

  @spec age(patient_case :: map()) :: pos_integer() | nil
  @spec age(patient_case :: map(), as_of :: DateTime.t()) :: pos_integer() | nil
  def age(patient_case, as_of \\ Timex.local()) do
    case date_of_birth(patient_case) do
      nil -> nil
      dob -> do_age(dob, as_of)
    end
  end

  defp do_age(dob, as_of) do
    age = as_of.year - dob.year

    if as_of.month < dob.month || (as_of.month == dob.month && as_of.day < dob.day),
      do: age - 1,
      else: age
  end

  def date_of_birth(patient_case),
    do: patient_case |> property("dob") |> parse_date()

  def properties(patient_case),
    do: Map.get(patient_case, "properties", %{})

  def property(patient_case, property, default \\ nil),
    do: patient_case |> properties() |> Map.get(property, default)

  def parse_date(nil), do: nil

  def parse_date(date_string) do
    case Date.from_iso8601(date_string) do
      {:ok, date} -> date
      {:error, _} -> nil
    end
  end

  def domain(%{"domain" => domain}), do: domain
  def domain(_), do: nil

  def case_id(%{"case_id" => case_id}), do: case_id
  def case_id(_), do: nil

  def child_cases(%{"child_cases" => child_cases}), do: Map.values(child_cases)

  def current_status(patient_case),
    do: property(patient_case, "current_status")

  def owner_id(patient_case),
    do: property(patient_case, "owner_id")

  def full_name(patient_case),
    do: property(patient_case, "full_name")

  def first_name(patient_case),
    do: property(patient_case, "first_name")

  def last_name(patient_case),
    do: property(patient_case, "last_name")

  def phone(patient_case),
    do: property(patient_case, "phone_home")

  def has_date_of_birth?(patient_case) do
    !!date_of_birth(patient_case)
  end

  def has_phone_number?(patient_case) do
    patient_case
    |> property("has_phone_number")
    |> is_yes?()
  end

  def initials(patient_case),
    do: property(patient_case, "initials")

  @secure_id_property "smc_id"

  def secure_id(patient_case),
    do: property(patient_case, @secure_id_property)

  def secure_id_property, do: @secure_id_property

  def smc_opt_in?(patient_case),
    do: property(patient_case, "smc_opt_in") |> is_yes?()

  def smc_trigger_reason(patient_case),
    do: property(patient_case, "smc_trigger_reason")

  def transaction_id(patient_case),
    do: property(patient_case, "smc_transaction_id")

  def investigation?(patient_case),
    do: property(patient_case, "investigation")

  def investigation_name(patient_case),
    do: property(patient_case, "investigation_name")

  def investigation_case_id(patient_case),
    do: property(patient_case, "investigation_case_id")

  def investigation_id(patient_case),
    do: property(patient_case, "investigation_id")

  def isolation_start_date(patient_case),
    do: patient_case |> property("isolation_start_date") |> parse_date()

  def new_lab_result_specimen_collection_date(patient_case),
    do: patient_case |> property("new_lab_result_specimen_collection_date") |> parse_date()

  def start_of_infectious_period(patient_case),
    do:
      (isolation_start_date(patient_case) || new_lab_result_specimen_collection_date(patient_case))
      |> Timex.shift(days: -2)

  def end_of_infectious_period(patient_case),
    do: patient_case |> start_of_infectious_period() |> Timex.shift(days: 10)

  def infectious_period(patient_case),
    do: Date.range(start_of_infectious_period(patient_case), end_of_infectious_period(patient_case))

  def case_type(commcare_case), do: commcare_case |> property("case_type") |> to_string() |> String.downcase()
  def is_contact?(commcare_case), do: case_type(commcare_case) == "contact"
  def is_patient?(commcare_case), do: case_type(commcare_case) == "patient"

  def is_minor?(patient_case, as_of \\ Timex.local()),
    do: age(patient_case, as_of) < @minimum_age

  def minimum_age, do: @minimum_age

  def patient_type(commcare_case), do: commcare_case |> property("patient_type") |> to_string() |> String.downcase()

  defp generate_random(n),
    do: Enum.map(0..(n - 1), fn _ -> [?0..?9] |> Enum.concat() |> Enum.random() end)

  def generate_contact_id(patient_case) do
    case doh_mpi_id(patient_case) do
      nil -> 6 |> generate_random() |> to_string()
      doh_mpi -> "#{doh_mpi}-#{generate_random(6)}"
    end
  end

  def doh_mpi_id(patient) do
    case property(patient, "doh_mpi_id") do
      nil -> nil
      "" -> nil
      mpi_id -> mpi_id
    end
  end

  def primary_language(patient_case),
    do: property(patient_case, "primary_language", "en")

  def is_stub?(patient_case),
    do: patient_case |> property("stub") |> is_yes?()

  def transfer_status(patient_case),
    do: property(patient_case, "transfer_status")

  def external_id(patient_case) do
    with domain when is_binary(domain) <- domain(patient_case),
         case_id when is_binary(case_id) <- case_id(patient_case) do
      "gid://commcare/domain/#{domain}/case/#{case_id}"
    else
      _ -> nil
    end
  end

  def existing_contacts(patient_case) do
    patient_case
    |> child_cases()
    |> Enum.filter(&is_contact?/1)
    |> Enum.map(fn contact ->
      %Contact{
        first_name: first_name(contact),
        last_name: last_name(contact),
        phone: phone(contact)
      }
    end)
  end

  def days_between_open_and_modified(patient_case) do
    with date_opened when not is_nil(date_opened) <-
           property(patient_case, "date_opened") |> Parsers.datetime_with_or_without_zone(),
         server_date_modified when not is_nil(server_date_modified) <-
           patient_case["server_date_modified"] |> Parsers.datetime_with_or_without_zone() do
      difference = DateTime.diff(server_date_modified, date_opened)
      difference / (60 * 60 * 24)
    else
      _ -> :error
    end
  end

  def interview_attempted_or_completed?(patient_case) do
    property(patient_case, "interview_disposition") in [
      "invalid_phone_number",
      "agreed_to_participate",
      "deceased",
      "med_psych",
      "language_barrier",
      "incarcerated",
      "already_investigated",
      "facility_notification"
    ]
  end

  defp is_yes?("yes"), do: true
  defp is_yes?(_), do: false
end
