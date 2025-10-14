defmodule Shard.Repo.Migrations.AddNewDungeonToDoors do
  use Ecto.Migration

  def change do
    alter table(:doors) do
      add :new_dungeon, :boolean, default: false
    end
  end
end
