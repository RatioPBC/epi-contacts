defmodule EpiContacts.UnlockIdentityConfirmationSessionWorker do
  @moduledoc """
  Oban worker that unlocks a confirm identity
  """

  use Oban.Worker, queue: :default

  alias EpiContacts.Questionnaire
  alias EpiContacts.Repo

  def schedule_in do
    15 * 60
  end

  @impl Oban.Worker
  def perform(%_{args: %{"session_id" => id}}) do
    session = Questionnaire.get_identity_confirmation_session(id)
    changeset = Questionnaire.change_identity_confirmation_session(session, %{unlocked_at: DateTime.utc_now()})
    {:ok, _} = Repo.update(changeset)

    :ok
  end
end
