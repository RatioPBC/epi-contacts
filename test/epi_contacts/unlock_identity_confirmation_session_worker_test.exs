defmodule EpiContacts.UnlockIdentityConfirmationSessionWorkerTest do
  use EpiContacts.DataCase, async: true

  alias EpiContacts.{Questionnaire, IdentityConfirmationSession, UnlockIdentityConfirmationSessionWorker}

  describe "perform" do
    test "it updates the session corresponding to the given id to be unlocked" do
      {:ok, session} = Repo.insert(%IdentityConfirmationSession{external_id: "gid://external/id"})

      :ok = UnlockIdentityConfirmationSessionWorker.perform(%Oban.Job{args: %{"session_id" => session.id}})

      updated_session = Questionnaire.get_identity_confirmation_session(session.id)

      assert updated_session.unlocked_at
    end
  end

  describe "schedule_in" do
    test "it returns 15 minutes in seconds" do
      assert UnlockIdentityConfirmationSessionWorker.schedule_in() == 900
    end
  end
end
