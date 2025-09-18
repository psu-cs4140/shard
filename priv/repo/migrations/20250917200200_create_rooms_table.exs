defmodule Shard.Repo.Migrations.CreateRoomsTable do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string, null: false
      add :description, :text
      add :x, :integer, default: 0
      add :y, :integer, default: 0
      add :north_door_id, references(:doors, on_delete: :nilify_all)
      add :east_door_id, references(:doors, on_delete: :nilify_all)
      add :south_door_id, references(:doors, on_delete: :nilify_all)
      add :west_door_id, references(:doors, on_delete: :nilify_all)
      timestamps(type: :utc_datetime)
    end
  end
end
