defmodule Shard.Repo.Migrations.FixMarketplaceListingCascade do
  use Ecto.Migration

  def up do
    # Drop the existing foreign key constraint
    execute "ALTER TABLE marketplace_listings DROP CONSTRAINT marketplace_listings_character_inventory_id_fkey"

    # Add it back with SET NULL instead of CASCADE DELETE
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
    execute "ALTER TABLE marketplace_listings DROP CONSTRAINT marketplace_listings_character_inventory_id_fkey"

    # Add it back with CASCADE DELETE (original behavior)
    execute """
    ALTER TABLE marketplace_listings
    ADD CONSTRAINT marketplace_listings_character_inventory_id_fkey
    FOREIGN KEY (character_inventory_id)
    REFERENCES character_inventories(id)
    ON DELETE CASCADE
    """
  end
end
