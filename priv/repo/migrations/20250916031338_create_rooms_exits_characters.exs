defmodule Shard.Repo.Migrations.CreateRoomsExitsCharacters do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :x, :integer, null: false, default: 0
      add :y, :integer, null: false, default: 0
      add :description, :text, null: false, default: ""
      timestamps()
    end

    create unique_index(:rooms, [:slug])

    create table(:exits) do
      # "north" | "east" | "south" | "west"
      add :dir, :string, null: false
      add :from_room_id, references(:rooms, on_delete: :delete_all), null: false
      add :to_room_id, references(:rooms, on_delete: :restrict), null: false
      timestamps()
    end

    create index(:exits, [:from_room_id])
    create index(:exits, [:to_room_id])

    create table(:characters) do
      add :name, :string, null: false
      add :current_room_id, references(:rooms, on_delete: :nilify_all), null: false
      timestamps()
    end

    create index(:characters, [:current_room_id])
  end
end
