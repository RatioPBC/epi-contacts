defmodule EpiContacts.CommcareSmsTrigger do
  @moduledoc """
  Encapsulates the logic as to if a case should be updated with a secure_id.
  """

  use Oban.Worker, queue: :default
  require Logger

  alias EpiContacts.{Commcare, Encryption, PatientCase}

  defmodule PatientCaseWrapper do
    @moduledoc """
    A stuct that wraps the data, mainly so we can roll out county-by-county via FunWithFlags.
    """
    defstruct [:patient_case]

    def new(params) do
      %__MODULE__{
        patient_case: params
      }
    end
  end

  defimpl FunWithFlags.Actor, for: PatientCaseWrapper do
    def id(%{patient_case: patient_case}) do
      domain = PatientCase.domain(patient_case)
      "domain:#{domain}"
    end
  end

  @sms_trigger_feature_flag :commcare_secure_id
  @pre_ci_feature_flag :pre_ci
  @pre_ci_surge_feature_flag :pre_ci_surge
  @maximum_pre_ci_case_age 10

  # years old; don't send to minors
  @minimum_age 18
  @minimum_age_feature_flag :minimum_age
  @minors_feature_flag :minors

  def sms_trigger_feature_flag, do: @sms_trigger_feature_flag
  def pre_ci_feature_flag, do: @pre_ci_feature_flag
  def pre_ci_surge_feature_flag, do: @pre_ci_surge_feature_flag
  def minimum_age_feature_flag, do: @minimum_age_feature_flag
  def minors_feature_flag, do: @minors_feature_flag

  @doc """
  Accepts a patient case, encrypts it, and inserts the job.
  """
  @spec enqueue!(map) :: Oban.Job.t()
  def enqueue!(patient_case) do
    patient_case
    |> prepare_args()
    |> new()
    |> Oban.insert!()
  end

  @spec prepare_args(map) :: map()
  @doc """
  Sets up the encrypted patient case and nonce arguments so that
  any perform/1 can decrypt the patient case.

  Returns %{
    "case_id" => String.t(),
    "domain" => String.t(),
    "encrypted_patient_case" => String.t(),
    "nonce" => String.t()
  }
  """
  def prepare_args(%{"case_id" => case_id, "domain" => domain, "properties" => _properties} = patient_case) do
    {encrypted_patient_case, nonce} = Encryption.encrypt(patient_case)

    %{
      "case_id" => case_id,
      "domain" => domain,
      "encrypted_patient_case" => encrypted_patient_case,
      "nonce" => nonce
    }
  end

  defp determine_trigger_reason_for_logging(:pre_ci) do
    if FunWithFlags.enabled?(@pre_ci_surge_feature_flag),
      do: :pre_ci_surge,
      else: :pre_ci
  end

  defp determine_trigger_reason_for_logging(reason),
    do: reason

  @impl Oban.Worker
  def perform(%_{args: %{"encrypted_patient_case" => encrypted_patient_case, "nonce" => nonce}}) do
    with {:ok, patient_case} <- Encryption.decrypt(encrypted_patient_case, nonce),
         transaction_id = Ecto.UUID.generate(),
         log_transaction(patient_case, transaction_id, "sms_trigger_starting"),
         {true, trigger_decision} <- case_meets_preconditions?(patient_case, transaction_id),
         loggable_trigger_reason <- determine_trigger_reason_for_logging(trigger_decision),
         true <- case_meets_conditions?(patient_case, transaction_id, trigger_decision),
         {:ok, _trigger_reason} <- trigger_sms(loggable_trigger_reason, patient_case, transaction_id) do
      analytics_reporter().report_sms_triggered(
        patient_case: patient_case,
        reason: loggable_trigger_reason,
        timestamp: DateTime.utc_now()
      )

      :ok
    else
      {:error, reason} -> {:error, reason}
      {false, nil} -> {:discard, :not_triggered}
      {{:error, reason}, _trigger_reason} -> {:error, reason}
      false -> {:discard, "conditions not met"}
      {false, _} -> {:discard, "preconditions not met"}
    end
  end

  def trigger_sms(nil, _patient_case, _transaction_id), do: {false, nil}

  def trigger_sms(trigger_reason, patient_case, transaction_id) do
    {
      domain,
      case_id,
      patient_case_properties
    } = Commcare.PatientCase.properties_for_update(patient_case, transaction_id, trigger_reason)

    sms_trigger_result =
      commcare_client().update_properties!(
        domain,
        case_id,
        patient_case_properties
      )

    {sms_trigger_result, trigger_reason}
  end

  def case_meets_preconditions?(patient_case, transaction_id) do
    post_ci_triggered = post_ci_triggered?(patient_case)
    pre_ci_triggered = pre_ci_triggered?(patient_case)
    pre_ci_minor_triggered = pre_ci_minor_triggered?(patient_case)

    trigger_reason = trigger_reason(post_ci_triggered, pre_ci_minor_triggered, pre_ci_triggered)
    pre_ci_minor_triggered_and_feature_flag_disabled = pre_ci_minor_triggered && disabled_for_minors?()

    preconditions_met =
      if pre_ci_minor_triggered_and_feature_flag_disabled,
        do: false,
        else: post_ci_triggered || pre_ci_triggered

    log_transaction(patient_case, transaction_id, "sms_trigger_preconditions", %{
      case_eligible_for_sms: case_eligible_for_sms?(patient_case),
      case_eligible_for_pre_ci: case_eligible_for_pre_ci?(patient_case),
      case_is_manually_triggered: case_is_manually_triggered?(patient_case),
      trigger_reason: trigger_reason,
      preconditions_met: preconditions_met,
      post_ci_triggered: post_ci_triggered,
      pre_ci_triggered: pre_ci_triggered,
      pre_ci_minor_triggered: pre_ci_minor_triggered,
      pre_ci_minor_triggered_and_feature_flag_disabled: pre_ci_minor_triggered_and_feature_flag_disabled
    })

    {preconditions_met, trigger_reason}
  end

  defp post_ci_triggered?(patient_case) do
    case_eligible_for_sms?(patient_case) && case_is_manually_triggered?(patient_case)
  end

  defp pre_ci_triggered?(patient_case) do
    case_eligible_for_sms?(patient_case) && case_eligible_for_pre_ci?(patient_case) &&
      !case_is_manually_triggered?(patient_case)
  end

  defp pre_ci_minor_triggered?(patient_case) do
    pre_ci_triggered?(patient_case) && PatientCase.is_minor?(patient_case)
  end

  defp trigger_reason(true, _, _), do: :post_ci
  defp trigger_reason(false, true, _), do: :pre_ci_minor
  defp trigger_reason(false, false, true), do: :pre_ci
  defp trigger_reason(_, _, _), do: nil

  def minimum_age, do: @minimum_age

  defp case_eligible_for_sms?(patient_case) do
    FunWithFlags.enabled?(@sms_trigger_feature_flag, for: PatientCaseWrapper.new(patient_case))
  end

  defp case_eligible_for_pre_ci?(patient_case) do
    FunWithFlags.enabled?(@pre_ci_feature_flag, for: PatientCaseWrapper.new(patient_case))
  end

  defp disabled_for_minors?, do: !FunWithFlags.enabled?(@minors_feature_flag)

  defp case_is_manually_triggered?(patient_case) do
    PatientCase.smc_opt_in?(patient_case)
  end

  defp acceptable_current_status?(patient_case) do
    PatientCase.current_status(patient_case) != "closed"
  end

  defp acceptable_patient_type?(patient_case) do
    PatientCase.patient_type(patient_case) != "pui"
  end

  defp acceptable_stub?(patient_case) do
    !PatientCase.is_stub?(patient_case)
  end

  defp acceptable_transfer_status?(patient_case) do
    PatientCase.transfer_status(patient_case) not in ["pending", "sent"]
  end

  defp absent_secure_id?(patient_case) do
    patient_case
    |> PatientCase.secure_id()
    |> Euclid.Term.blank?()
  end

  def case_meets_conditions?(patient_case, transaction_id, trigger_reason) do
    [
      acceptable_case_age?(trigger_reason),
      acceptable_interview_disposition?(trigger_reason),
      &absent_secure_id?/1,
      &acceptable_current_status?/1,
      &acceptable_patient_type?/1,
      &acceptable_stub?/1,
      &acceptable_transfer_status?/1,
      &PatientCase.has_date_of_birth?/1,
      &PatientCase.has_phone_number?/1
    ]
    |> Enum.all?(fn check -> check_property(check, patient_case, transaction_id) end)
    |> log_result_of_checks(patient_case, transaction_id)
  end

  defp acceptable_case_age?(:post_ci), do: fn _ -> true end

  defp acceptable_case_age?(_trigger_reason) do
    fn patient_case ->
      PatientCase.days_between_open_and_modified(patient_case)
      |> case do
        :error -> true
        days -> days < @maximum_pre_ci_case_age
      end
    end
  end

  defp acceptable_interview_disposition?(:post_ci), do: fn _ -> true end

  defp acceptable_interview_disposition?(_trigger_reason) do
    fn patient_case ->
      !PatientCase.interview_attempted_or_completed?(patient_case)
    end
  end

  defp log_result_of_checks(result, patient_case, transaction_id) do
    log_transaction(patient_case, transaction_id, "sms_trigger_all_checks", %{result: result})
    result
  end

  defp check_property(check, patient_case, transaction_id) do
    result = check.(patient_case)

    if FunWithFlags.enabled?(:commcare_secure_id_check_logging) do
      check_info = Function.info(check)
      check_name = Keyword.get(check_info, :name)

      log_transaction(patient_case, transaction_id, "sms_trigger_check_property", %{
        check_name: check_name,
        result: result
      })
    end

    result
  end

  defp log_transaction(patient_case, transaction_id, message, metadata \\ %{}) do
    metainfo = %{
      module: __MODULE__,
      commcare_case_id: PatientCase.case_id(patient_case),
      commcare_domain: PatientCase.domain(patient_case),
      transaction: transaction_id
    }

    Logger.info(message, Map.merge(metadata, metainfo))
  end

  defp analytics_reporter, do: Application.get_env(:epi_contacts, :analytics_reporter)
  defp commcare_client, do: Application.get_env(:epi_contacts, :commcare_client)
end
