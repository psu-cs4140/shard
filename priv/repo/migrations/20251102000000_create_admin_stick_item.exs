defmodule Shard.Repo.Migrations.CreateAdminStickItem do
  use Ecto.Migration

  def up do
    # Insert the Admin Stick item
    execute """
    INSERT INTO items (name, description, item_type, rarity, equippable, stackable, usable, is_active, inserted_at, updated_at)
    VALUES (
      'Admin Zone Editing Stick',
      'A magical stick that allows admins to modify zones',
      'tool',
      'legendary',
      false,
      false,
      true,
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING;
    """
  end

  def down do
    # Remove the Admin Stick item
    execute """
    DELETE FROM items WHERE name = 'Admin Zone Editing Stick';
    """
  end
end
