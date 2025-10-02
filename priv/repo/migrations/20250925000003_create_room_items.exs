defmodule Shard.Repo.Migrations.CreateRoomItems do
  use Ecto.Migration

  def change do
    create table(:room_items) do
      add :location, :string, null: false
      add :item_id, references(:items, on_delete: :delete_all), null: false
      add :quantity, :integer, default: 1
      add :x_position, :decimal, precision: 8, scale: 2, default: 0.0
      add :y_position, :decimal, precision: 8, scale: 2, default: 0.0
      add :dropped_by_character_id, references(:characters, on_delete: :nilify_all)
      add :respawn_timer, :utc_datetime
      add :is_permanent, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:room_items, [:location])
    create index(:room_items, [:item_id])
    create index(:room_items, [:dropped_by_character_id])
  end
end
