defmodule Shard.Repo.Migrations.CreatePlayerPositions do
  use Ecto.Migration

  def change do
    create table(:player_positions) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :zone_id, references(:zones, on_delete: :delete_all), null: false
      add :room_id, references(:rooms, on_delete: :delete_all), null: false
      add :x_coordinate, :integer, null: false
      add :y_coordinate, :integer, null: false
      add :z_coordinate, :integer, default: 0, null: false
      add :last_visited_at, :utc_datetime, null: false

      timestamps()
    end

    create unique_index(:player_positions, [:character_id, :zone_id])
    create index(:player_positions, [:character_id])
    create index(:player_positions, [:zone_id])
    create index(:player_positions, [:room_id])
  end
end
