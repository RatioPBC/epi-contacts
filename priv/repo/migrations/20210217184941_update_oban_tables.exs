defmodule EpiContacts.Repo.Migrations.UpdateObanTables do
  use Ecto.Migration

  def up do
    Oban.Migrations.up(version: 10)
  end

  def down do
    Oban.Migrations.down(version: 8)
  end
end
