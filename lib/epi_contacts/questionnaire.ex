defmodule EpiContacts.Questionnaire do
  @moduledoc """
  Ecto context for managing identity confirmation.
  """

  alias EpiContacts.{ConfirmIdentity, IdentityConfirmationSession, Repo}

  def change_confirm_identity(%ConfirmIdentity{} = confirm_identity, attrs \\ %{}) do
    ConfirmIdentity.changeset(confirm_identity, attrs)
  end

  def change_identity_confirmation_session(%IdentityConfirmationSession{} = identity_confirmation_session, attrs \\ %{}) do
    IdentityConfirmationSession.changeset(identity_confirmation_session, attrs)
  end

  def get_identity_confirmation_session(session_id) do
    Repo.get(IdentityConfirmationSession, session_id)
  end
end
