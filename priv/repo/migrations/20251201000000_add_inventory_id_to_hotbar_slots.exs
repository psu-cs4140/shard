defmodule Shard.Repo.Migrations.AddInventoryIdToHotbarSlots do
  use Ecto.Migration

  def change do
    # This migration is a no-op since inventory_id already exists in the hotbar_slots table
    # from the original create_hotbar_slots migration (20250925000004)
    
    # Only add the column if it doesn't already exist
    execute """
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'hotbar_slots' 
        AND column_name = 'inventory_id'
      ) THEN
        ALTER TABLE hotbar_slots 
        ADD COLUMN inventory_id bigint REFERENCES character_inventories(id) ON DELETE CASCADE;
      END IF;
    END
    $$;
    """

    # Only create the index if it doesn't already exist
    execute """
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'hotbar_slots' 
        AND indexname = 'hotbar_slots_inventory_id_index'
      ) THEN
        CREATE INDEX hotbar_slots_inventory_id_index ON hotbar_slots (inventory_id);
      END IF;
    END
    $$;
    """
  end
end
