defmodule EpiLocator.Repo.Migrations.RemoveObanBeatsTables do
  use Ecto.Migration

  def up do
    drop_if_exists table("oban_beats")
  end

  def down do
    raise Ecto.MigrationError, message: "manually add Oban beats_table back"
  end
end
