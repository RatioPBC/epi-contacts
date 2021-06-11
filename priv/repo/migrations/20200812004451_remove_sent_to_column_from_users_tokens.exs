defmodule EpiContacts.Repo.Migrations.RemoveSendToColumnFromUsersTokens do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      remove(:sent_to, :string)
    end
  end
end
