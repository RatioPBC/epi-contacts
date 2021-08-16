defmodule EpiContacts.Commcare.ClientBehaviour do
  @moduledoc """
  this module defines the Commcare Client Behaviour
  """
  @callback get_case(domain :: String.t(), case_id :: String.t()) :: {:ok, map()} | {:error, atom()}
  @callback update_properties!(domain :: String.t(), case_id :: String.t(), properties :: keyword() | map()) ::
              :ok | {:error, any()}
end

defmodule EpiContacts.Commcare.Client do
  @behaviour EpiContacts.Commcare.ClientBehaviour

  import XmlBuilder

  alias EpiContacts.{PatientCase, Contact}
  alias EpiContacts.Commcare.Api

  @moduledoc """
  this module provides a way to update the properties of a commcare case
  """

  @impl EpiContacts.Commcare.ClientBehaviour
  def update_properties!(domain, case_id, properties, opts \\ []) do
    [update: properties] |> build(case_id, opts) |> Api.post_case(domain)
  end

  @spec build_update(id :: binary(), properties :: keyword() | map()) :: binary()
  @spec build_update(id :: binary(), properties :: keyword() | map(), opts :: []) :: binary()
  def build_update(id, properties, opts \\ []), do: [update: properties] |> build(id, opts)

  @impl EpiContacts.Commcare.ClientBehaviour
  def get_case(domain, case_id),
    do: Api.get_case(case_id, domain)

  def build(properties, id, opts \\ []) do
    envelope_id = opts[:envelope_id] || Ecto.UUID.generate()
    envelope_timestamp = Keyword.get_lazy(opts, :envelope_timestamp, fn -> DateTime.utc_now() end)

    element(:data, %{xmlns: "http://dev.commcarehq.org/jr/xforms"}, [
      element(
        :case,
        %{case_id: id, user_id: user_id(), xmlns: "http://commcarehq.org/case/transaction/v2"},
        Enum.map(properties, fn {verb, properties} ->
          element(
            verb,
            Enum.map(properties, fn
              {name, true} -> element(name, "yes")
              {name, false} -> element(name, "no")
              {name, value} -> element(name, value)
              {name, attributes, content} -> {name, attributes, content}
            end)
          )
        end)
      ),
      meta(envelope_id, envelope_timestamp)
    ])
    |> document()
    |> generate(format: :none)
  end

  def format_date(date), do: Timex.format!(date, "{YYYY}-{M}-{D}")

  def build_contact(patient_case, contact, opts \\ []) do
    case_data = %{
      first_name: Contact.first_name(contact),
      last_name: Contact.last_name(contact),
      full_name: Contact.full_name(contact),
      name: Contact.full_name(contact),
      contact_id: Contact.contact_id(contact),
      initials: Contact.initials(contact),
      phone_home: Contact.phone(contact),
      has_phone_number: Contact.has_phone_number?(contact),
      contact_is_a_minor: Contact.is_minor?(contact),
      relation_to_case: Contact.relationship(contact),
      contact_type: Contact.contact_type(contact),
      commcare_email_address: Contact.email(contact),
      primary_language: Contact.primary_language(contact),
      exposure_date: contact |> Contact.exposed_on() |> format_date(),
      fup_start_date: contact |> Contact.exposed_on() |> format_date(),
      fup_end_date: contact |> Contact.exposed_on() |> Date.add(14) |> format_date(),
      fup_next_type: "initial_interview",
      fup_next_method: "call",
      fup_next_call_date: Timex.today() |> format_date(),
      contact_status: "pending_first_contact",
      owner_id: PatientCase.owner_id(patient_case),
      investigation: PatientCase.investigation?(patient_case),
      investigation_name: PatientCase.investigation_name(patient_case),
      investigation_case_id: PatientCase.investigation_case_id(patient_case),
      investigation_id: PatientCase.investigation_id(patient_case),
      smc_trigger_reason: PatientCase.smc_trigger_reason(patient_case),
      has_index_case: true,
      elicited_from_smc: true
    }

    case_data =
      if FunWithFlags.enabled?(:feb_17_commcare_release) do
        case_data |> Map.put(:index_case_id, PatientCase.doh_mpi_id(patient_case))
      else
        case_data
      end

    parent_case_metadata =
      if FunWithFlags.enabled?(:feb_17_commcare_release) do
        %{case_type: "patient", relationship: "extension"}
      else
        %{case_type: "patient"}
      end

    [
      create: [case_name: Contact.full_name(contact), case_type: :contact],
      update: case_data,
      index: [{:parent, parent_case_metadata, PatientCase.case_id(patient_case)}]
    ]
    |> build(UUID.uuid4(), opts)
  end

  def post_contact(patient_case, contact, envelope_id) do
    patient_case
    |> build_contact(contact, envelope_id)
    |> Api.post_case(PatientCase.domain(patient_case))
  end

  defp user_id, do: Application.fetch_env!(:epi_contacts, :commcare_user_id)

  defp meta(envelope_id, envelope_timestamp) do
    element(:"n1:meta", %{"xmlns:n1": "http://openrosa.org/jr/xforms"}, [
      element(:"n1:deviceID", "Formplayer"),
      element(:"n1:timeStart", to_string(envelope_timestamp)),
      element(:"n1:timeEnd", to_string(envelope_timestamp)),
      element(:"n1:username", Application.get_env(:epi_contacts, :commcare_username)),
      element(:"n1:userID", Application.get_env(:epi_contacts, :commcare_user_id)),
      element(:"n1:instanceID", envelope_id)
    ])
  end
end
