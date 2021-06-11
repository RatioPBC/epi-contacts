defmodule EpiContacts.ConfirmIdentity do
  @moduledoc """
  confirms the user's dob matches the one they provided
  """

  use Ecto.Schema
  import Ecto.Changeset

  import EpiContacts.Gettext

  alias EpiContacts.{
    Questionnaire,
    Repo,
    UnlockIdentityConfirmationSessionWorker,
    PatientCase,
    IdentityConfirmationSession
  }

  alias IdentityConfirmationSession.Attempt

  embedded_schema do
    field(:dob, :date)
  end

  def changeset(confirm_identity, attrs) do
    cast(confirm_identity, attrs, [:dob])
  end

  def verify_correct_date_of_birth(confirm_identity, attrs, patient_case) do
    session = upsert_identity_confirmation_session(patient_case)

    {changeset, session} =
      confirm_identity
      |> changeset(attrs)
      |> validate(patient_case)
      |> record_attempt(session)

    if is_locked_out?(session) do
      {:error, :locked_out}
    else
      Ecto.Changeset.apply_action(changeset, :validate)
    end
  end

  defp validate(changeset, patient_case) do
    changeset
    |> validate_required([:dob])
    |> validate_change(
      :dob,
      fn :dob, dob ->
        patient_case
        |> PatientCase.date_of_birth()
        |> Date.compare(dob)
        |> case do
          :eq -> []
          _ -> [dob: dgettext_noop("errors", "is not correct")]
        end
      end
    )
  end

  defp is_locked_out?(%IdentityConfirmationSession{locked_at: locked_at}) when is_nil(locked_at), do: false
  defp is_locked_out?(%IdentityConfirmationSession{locked_at: _locked_at}), do: true

  def upsert_identity_confirmation_session(patient_case) do
    session = %IdentityConfirmationSession{external_id: PatientCase.external_id(patient_case)}

    {:ok, session} =
      Repo.insert(session,
        returning: true,
        on_conflict: {:replace, [:external_id]},
        conflict_target: {:unsafe_fragment, IdentityConfirmationSession.upsert_conflict_target()}
      )

    session
  end

  def record_attempt(changeset, session, limit \\ 6)

  @doc false
  def record_attempt(%Ecto.Changeset{valid?: true} = changeset, session, _limit) do
    dob = Ecto.Changeset.get_field(changeset, :dob)
    {:ok, session} = add_attempt_to_session(%Attempt{dob: dob, successful: true}, session)

    {changeset, session}
  end

  @doc false
  def record_attempt(%Ecto.Changeset{valid?: false} = changeset, session, limit) do
    dob = Ecto.Changeset.get_field(changeset, :dob)

    {:ok, %IdentityConfirmationSession{} = session} =
      %Attempt{dob: dob, successful: false}
      |> add_attempt_to_session(session)

    session.attempts
    |> Enum.reject(& &1.successful)
    |> length()
    |> Kernel.==(limit)
    |> if do
      {:ok, session} = lock_session(session)

      {changeset, session}
    else
      {changeset, session}
    end
  end

  defp add_attempt_to_session(%Attempt{} = attempt, %IdentityConfirmationSession{attempts: attempts} = session) do
    session
    |> Questionnaire.change_identity_confirmation_session()
    |> Ecto.Changeset.put_embed(:attempts, attempts ++ [attempt])
    |> Repo.update()
  end

  defp lock_session(%IdentityConfirmationSession{} = session) do
    {:ok, session} =
      session
      |> Questionnaire.change_identity_confirmation_session(%{locked_at: DateTime.utc_now()})
      |> Repo.update()

    %{session_id: session.id}
    |> UnlockIdentityConfirmationSessionWorker.new(schedule_in: UnlockIdentityConfirmationSessionWorker.schedule_in())
    |> Oban.insert!()

    {:ok, session}
  end
end
