defmodule Shard.Repo.Migrations.AddXYColumnsToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :x, :integer, default: 0
      add :y, :integer, default: 0
    end
  end
end
