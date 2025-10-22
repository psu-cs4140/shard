defmodule Shard.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string, null: false
      add :description, :text
      add :x_coordinate, :integer, default: 0
      add :y_coordinate, :integer, default: 0
      add :z_coordinate, :integer, default: 0
      add :is_public, :boolean, default: true, null: false
      add :room_type, :string, default: "standard"
      add :properties, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rooms, [:name])
    create unique_index(:rooms, [:x_coordinate, :y_coordinate, :z_coordinate])
  end
end
