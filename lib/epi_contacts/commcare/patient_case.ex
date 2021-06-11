defmodule EpiContacts.Commcare.PatientCase do
  @moduledoc """
  Presenter for updating patient case properties
  """
  alias EpiContacts.PatientCase
  alias EpiContacts.SecureId

  @callout_property_name "has_triggered_smc_callout"
  @id_property_name PatientCase.secure_id_property()

  def callout_property_name, do: @callout_property_name

  def properties_for_update(patient_case, transaction_id, trigger_reason) do
    case_id = PatientCase.case_id(patient_case)
    domain = PatientCase.domain(patient_case)

    secure_id = SecureId.encode(%{d: domain, c: case_id, txn_id: transaction_id})

    {
      domain,
      case_id,
      properties(
        patient_case,
        secure_id,
        transaction_id,
        trigger_reason
      )
    }
  end

  defp properties(patient_case, secure_id, transaction_id, trigger_reason) do
    %{
      @callout_property_name => true,
      @id_property_name => secure_id,
      "contact_phone_number_is_verified" => 1,
      "smc_transaction_id" => transaction_id,
      "smc_trigger_reason" => to_string(trigger_reason)
    }
    |> add_initials_if_missing(patient_case)
  end

  defp add_initials_if_missing(properties, patient_case) do
    case PatientCase.initials(patient_case) do
      nil -> Map.put(properties, "initials", initials(patient_case))
      _ -> properties
    end
  end

  defp initials(patient_case) do
    first_initial = patient_case |> PatientCase.first_name() |> to_string() |> String.first()
    last_initial = patient_case |> PatientCase.last_name() |> to_string() |> String.first()
    "#{first_initial}.#{last_initial}."
  end
end
