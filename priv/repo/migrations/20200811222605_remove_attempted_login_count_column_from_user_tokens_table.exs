defmodule EpiContacts.Repo.Migrations.RemoveAttemptedLoginCountColumnFromUserTokensTable do
  use Ecto.Migration

  def change do
    alter(table(:users_tokens)) do
      remove(:attempted_login_count, :integer, null: false, default: 0)
    end
  end
end
