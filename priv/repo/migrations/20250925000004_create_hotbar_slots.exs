defmodule Shard.Repo.Migrations.CreateHotbarSlots do
  use Ecto.Migration

  def change do
    create table(:hotbar_slots) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :slot_number, :integer, null: false
      add :item_id, references(:items, on_delete: :delete_all)
      add :inventory_id, references(:character_inventories, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:hotbar_slots, [:character_id, :slot_number])
    create index(:hotbar_slots, [:character_id])
    create index(:hotbar_slots, [:item_id])
  end
end
