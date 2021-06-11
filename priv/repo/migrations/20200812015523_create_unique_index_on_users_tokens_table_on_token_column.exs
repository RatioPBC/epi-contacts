defmodule EpiContacts.Repo.Migrations.CreateUniqueIndexOnUsersTokensTableOnTokenColumn do
  use Ecto.Migration

  def change do
    create(unique_index(:users_tokens, [:token]))
  end
end
