defmodule Shard.Repo.Migrations.CreateRoomsExitsCharacters do
  use Ecto.Migration

  def change do
    # ROOMS
    create table(:rooms) do
      add :name, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :x, :integer, null: false, default: 0
      add :y, :integer, null: false, default: 0
      timestamps()
    end

    create unique_index(:rooms, [:slug])
    create index(:rooms, [:x, :y])

    # EXITS
    create table(:exits) do
      add :dir, :string, null: false
      add :from_room_id, references(:rooms, on_delete: :delete_all), null: false
      add :to_room_id, references(:rooms, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:exits, [:from_room_id])
    create index(:exits, [:to_room_id])
    create unique_index(:exits, [:from_room_id, :dir], name: :exits_from_dir_uniq)
    create constraint(:exits, :dir_allowed, check: "dir IN ('n','s','e','w','up','down')")

    # CHARACTERS (minimal)
    create table(:characters) do
      add :name, :string, null: false
      add :room_id, references(:rooms, on_delete: :nilify_all)
      timestamps()
    end

    create index(:characters, [:room_id])
  end
end
