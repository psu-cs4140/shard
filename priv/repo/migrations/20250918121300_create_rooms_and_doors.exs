defmodule Shard.Repo.Migrations.CreateRoomsAndDoors do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string, null: false
      add :description, :text
      add :x_coordinate, :integer, default: 0
      add :y_coordinate, :integer, default: 0
      add :z_coordinate, :integer, default: 0
      add :is_public, :boolean, default: true
      add :room_type, :string, default: "standard"
      add :properties, :map, default: %{}
      
      timestamps(type: :utc_datetime)
    end

    create unique_index(:rooms, [:name])
    create index(:rooms, [:x_coordinate, :y_coordinate, :z_coordinate])

    create table(:doors) do
      add :name, :string
      add :description, :text
      add :from_room_id, references(:rooms, on_delete: :delete_all), null: false
      add :to_room_id, references(:rooms, on_delete: :delete_all), null: false
      add :direction, :string, null: false # north, south, east, west, up, down, etc.
      add :is_locked, :boolean, default: false
      add :key_required, :string
      add :door_type, :string, default: "standard"
      add :properties, :map, default: %{}
      
      timestamps(type: :utc_datetime)
    end

    create index(:doors, [:from_room_id])
    create index(:doors, [:to_room_id])
    create index(:doors, [:direction])
    create unique_index(:doors, [:from_room_id, :direction])
  end
end
