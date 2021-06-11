defmodule EpiContacts.Repo.Migrations.AddUniqueIndexToUnlockedAt do
  use Ecto.Migration

  alias EpiContacts.IdentityConfirmationSession

  def change do
    upsert_conflict_target = IdentityConfirmationSession.upsert_conflict_target()

    execute(
      "create unique index one_unlocked_session_per_external_id_idx on identity_confirmation_sessions #{
        upsert_conflict_target
      };"
    )
  end
end
