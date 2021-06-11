defmodule EpiContacts.Repo.Migrations.AddAttemptedLoginCount do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      add(:attempted_login_count, :integer, null: false, default: 0)
    end
  end
end
