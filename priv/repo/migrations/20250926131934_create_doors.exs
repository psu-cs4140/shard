defmodule Shard.Repo.Migrations.CreateDoors do
  use Ecto.Migration

  def change do
    create table(:doors) do
      add :direction, :string, null: false
      add :door_type, :string, null: false, default: "normal"
      add :is_locked, :boolean, null: false, default: false
      add :properties, :map, null: false, default: %{}

      add :from_room_id, references(:rooms, on_delete: :delete_all), null: false
      add :to_room_id, references(:rooms, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:doors, [:from_room_id])
    create index(:doors, [:to_room_id])
    create unique_index(:doors, [:from_room_id, :direction])
  end
end
