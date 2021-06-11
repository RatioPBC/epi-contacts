defmodule EpiContacts.ConfirmIdentityTest do
  use EpiContacts.DataCase, async: true

  alias EpiContacts.{
    ConfirmIdentity,
    IdentityConfirmationSession,
    Repo,
    UnlockIdentityConfirmationSessionWorker,
    PatientCase,
    Questionnaire
  }

  def build_patient_case,
    do: %{"properties" => %{"dob" => "1960-01-01"}, "domain" => "service", "case_id" => "identifier"}

  def with_patient_case(_), do: %{patient_case: build_patient_case()}

  describe "verify_correct_date_of_birth" do
    setup :with_patient_case

    test "it fails when no DOB is provided", %{patient_case: patient_case} do
      confirm = %ConfirmIdentity{}
      {:error, changeset} = ConfirmIdentity.verify_correct_date_of_birth(confirm, %{}, patient_case)

      refute changeset.valid?
      assert changeset.errors == [{:dob, {"can't be blank", [validation: :required]}}]
    end

    test "it fails when the birthdays do not match", %{patient_case: patient_case} do
      confirm = %ConfirmIdentity{}

      {:error, changeset} =
        ConfirmIdentity.verify_correct_date_of_birth(confirm, %{"dob" => "2020-01-10"}, patient_case)

      refute changeset.valid?
      assert changeset.errors == [dob: {"is not correct", []}]
    end

    test "it passes when the birthdays match", %{patient_case: patient_case} do
      confirm = %ConfirmIdentity{}

      {:ok, confirm_identity} =
        ConfirmIdentity.verify_correct_date_of_birth(confirm, %{"dob" => "1960-01-01"}, patient_case)

      assert confirm_identity.dob == ~D[1960-01-01]
    end

    test "it locks out the user when an invalid dob is provided six times", %{patient_case: patient_case} do
      attempts = List.duplicate(%IdentityConfirmationSession.Attempt{dob: "1980-01-01", successful: false}, 5)

      {:ok, session} =
        Repo.insert(%IdentityConfirmationSession{external_id: PatientCase.external_id(patient_case), attempts: attempts})

      {:error, :locked_out} =
        ConfirmIdentity.verify_correct_date_of_birth(%ConfirmIdentity{}, %{"dob" => "1980-01-01"}, patient_case)

      updated_session = Questionnaire.get_identity_confirmation_session(session.id)
      assert updated_session.locked_at
    end

    test "it enqueues an Oban worker to unlock the user when an invalid dob is provided six times", %{
      patient_case: patient_case
    } do
      attempts = List.duplicate(%IdentityConfirmationSession.Attempt{dob: "1980-01-01", successful: false}, 5)

      {:ok, session} =
        Repo.insert(%IdentityConfirmationSession{external_id: PatientCase.external_id(patient_case), attempts: attempts})

      ConfirmIdentity.verify_correct_date_of_birth(%ConfirmIdentity{}, %{"dob" => "1980-01-01"}, patient_case)

      scheduled_at = DateTime.add(DateTime.utc_now(), UnlockIdentityConfirmationSessionWorker.schedule_in())

      assert_enqueued(
        worker: UnlockIdentityConfirmationSessionWorker,
        args: %{"session_id" => session.id},
        scheduled_at: scheduled_at
      )
    end
  end

  describe "upsert_identity_confirmation_session" do
    setup :with_patient_case

    test "when no session exists for the given external id, it creates a new session", %{patient_case: patient_case} do
      refute Repo.get_by(IdentityConfirmationSession, external_id: PatientCase.external_id(patient_case))

      new_session = ConfirmIdentity.upsert_identity_confirmation_session(patient_case)

      assert Repo.aggregate(IdentityConfirmationSession, :count) == 1
      assert new_session.external_id == PatientCase.external_id(patient_case)
    end

    test "when a session exists for the given external id and unlocked_at is not set, it returns the existing session",
         %{patient_case: patient_case} do
      {:ok, existing_session} =
        Repo.insert(%IdentityConfirmationSession{external_id: PatientCase.external_id(patient_case)})

      new_session = ConfirmIdentity.upsert_identity_confirmation_session(patient_case)

      assert Repo.aggregate(IdentityConfirmationSession, :count) == 1
      assert new_session.id == existing_session.id
    end

    test "when a session exists for the given external id and unlocked_at is set, it creates a new session", %{
      patient_case: patient_case
    } do
      unlocked_at = NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)
      external_id = PatientCase.external_id(patient_case)

      {:ok, existing_session} =
        Repo.insert(%IdentityConfirmationSession{external_id: external_id, unlocked_at: unlocked_at})

      new_session = ConfirmIdentity.upsert_identity_confirmation_session(patient_case)

      ids = Repo.all(from(s in IdentityConfirmationSession, select: s.id, where: s.external_id == ^external_id))

      ids_set = MapSet.new(ids)

      assert MapSet.size(ids_set) == 2
      assert MapSet.member?(ids_set, existing_session.id)
      assert MapSet.member?(ids_set, new_session.id)
    end
  end

  describe "record_attempt/2" do
    setup do
      {:ok, session} = Repo.insert(%IdentityConfirmationSession{external_id: "gid://service/identifier"})

      %{session: session}
    end

    test "adds attempts against the active session for the given external id ", %{session: session} do
      changeset = Questionnaire.change_confirm_identity(%ConfirmIdentity{}, %{dob: "1980-01-01"})
      {_changeset, session} = ConfirmIdentity.record_attempt(changeset, session)

      assert length(session.attempts) == 1
      [attempt] = session.attempts

      assert attempt.successful
      assert attempt.dob == ~D[1980-01-01]

      changeset =
        %ConfirmIdentity{}
        |> Questionnaire.change_confirm_identity(%{dob: "1990-01-01"})
        |> Ecto.Changeset.add_error(:dob, "some message")

      {_changeset, session} = ConfirmIdentity.record_attempt(changeset, session)

      assert length(session.attempts) == 2
      [_, attempt] = session.attempts

      refute attempt.successful
      assert attempt.dob == ~D[1990-01-01]
    end

    test "doesn't lock the session when attempt is successful", %{session: session} do
      refute session.locked_at

      changeset = Questionnaire.change_confirm_identity(%ConfirmIdentity{}, %{dob: "1990-01-01"})

      {_changeset, session} = ConfirmIdentity.record_attempt(changeset, session, 1)

      assert length(session.attempts) == 1
      refute session.locked_at
    end

    test "locks the session when limit reached", %{session: session} do
      refute session.locked_at

      changeset =
        %ConfirmIdentity{}
        |> Questionnaire.change_confirm_identity(%{dob: "1990-01-01"})
        |> Ecto.Changeset.add_error(:dob, "some message")

      {_changeset, session} = ConfirmIdentity.record_attempt(changeset, session, 1)

      assert length(session.attempts) == 1
      assert session.locked_at
    end
  end
end
