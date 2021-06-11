defmodule EpiContacts.Repo.Migrations.AddIdentityConfirmationSessions do
  use Ecto.Migration

  def change do
    create table(:identity_confirmation_sessions, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:external_id, :string, null: false)
      add(:attempts, :map)
      add(:locked_at, :naive_datetime)
      add(:unlocked_at, :naive_datetime)
      timestamps()
    end
  end
end
