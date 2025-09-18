defmodule Shard.Repo.Migrations.CreateMudTables do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string, null: false
      add :description, :text
      add :north_door_id, references(:doors, on_delete: :nilify_all)
      add :east_door_id, references(:doors, on_delete: :nilify_all)
      add :south_door_id, references(:doors, on_delete: :nilify_all)
      add :west_door_id, references(:doors, on_delete: :nilify_all)
      timestamps(type: :utc_datetime)
    end

    create table(:doors) do
      add :is_open, :boolean, default: false, null: false
      add :is_locked, :boolean, default: false, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
