defmodule Shard.Repo.Migrations.AllowNullInventoryInMarketplace do
  use Ecto.Migration

  def up do
    # Drop the existing foreign key constraint
    execute "ALTER TABLE marketplace_listings DROP CONSTRAINT IF EXISTS marketplace_listings_character_inventory_id_fkey"

    # Make the column nullable
    alter table(:marketplace_listings) do
      modify :character_inventory_id, :bigint, null: true
    end

    # Add back the foreign key with SET NULL on delete
    execute """
    ALTER TABLE marketplace_listings
    ADD CONSTRAINT marketplace_listings_character_inventory_id_fkey
    FOREIGN KEY (character_inventory_id)
    REFERENCES character_inventories(id)
    ON DELETE SET NULL
    """
  end

  def down do
    # Drop the constraint
    execute "ALTER TABLE marketplace_listings DROP CONSTRAINT IF EXISTS marketplace_listings_character_inventory_id_fkey"

    # Make the column NOT NULL again
    alter table(:marketplace_listings) do
      modify :character_inventory_id, :bigint, null: false
    end

    # Add back the original foreign key with CASCADE DELETE
    execute """
    ALTER TABLE marketplace_listings
    ADD CONSTRAINT marketplace_listings_character_inventory_id_fkey
    FOREIGN KEY (character_inventory_id)
    REFERENCES character_inventories(id)
    ON DELETE CASCADE
    """
  end
end
