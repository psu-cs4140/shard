defmodule Shard.Repo.Migrations.AddInventoryIdToHotbarSlots do
  use Ecto.Migration

  def change do
    alter table(:hotbar_slots) do
      add :inventory_id, references(:character_inventories, on_delete: :delete_all)
    end

    create index(:hotbar_slots, [:inventory_id])
  end
end
