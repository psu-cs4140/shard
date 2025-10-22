defmodule Shard.Repo.Migrations.CreateDoors do
  use Ecto.Migration

  def change do
    create table(:doors) do
      add :name, :string
      add :description, :text
      add :direction, :string, null: false
      add :is_locked, :boolean, default: false, null: false
      add :key_required, :string
      add :door_type, :string, default: "standard"
      add :properties, :map, default: %{}
      add :new_dungeon, :boolean, default: false, null: false
      add :from_room_id, references(:rooms, on_delete: :delete_all), null: false
      add :to_room_id, references(:rooms, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:doors, [:from_room_id])
    create index(:doors, [:to_room_id])

    create unique_index(:doors, [:from_room_id, :direction],
             name: :doors_from_room_id_direction_index
           )
  end
end
