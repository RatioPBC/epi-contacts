defmodule EpiContacts.Repo.Migrations.RemoveContextColumnFromUsersTokens do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      remove(:context, :string, null: false)
    end
  end
end
