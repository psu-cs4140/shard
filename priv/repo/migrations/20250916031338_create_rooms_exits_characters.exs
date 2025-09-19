defmodule Shard.Repo.Migrations.CreateRoomsExitsCharacters do
  use Ecto.Migration

  def change do
    # 1) ROOMS
    create table(:rooms) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :description, :text, default: ""
      add :x, :integer, null: false
      add :y, :integer, null: false
      timestamps()
    end
    create unique_index(:rooms, [:slug])
    create unique_index(:rooms, [:x, :y])

    # 2) CHARACTERS (FK -> rooms)
    create table(:characters) do
      add :name, :string, null: false
      add :room_id, references(:rooms, on_delete: :nilify_all), null: true
      timestamps()
    end
    create index(:characters, [:room_id])

    # 3) EXITS (FKs -> rooms)
    create table(:exits) do
      add :from_id, references(:rooms, on_delete: :delete_all), null: false
      add :to_id,   references(:rooms, on_delete: :delete_all), null: false
      add :dir,     :string, null: false
      timestamps()
    end
    # unique(from_id, dir) is added later; keep this basic index here
    create index(:exits, [:to_id])
  end
end
