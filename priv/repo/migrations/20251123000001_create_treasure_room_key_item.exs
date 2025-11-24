defmodule Shard.Repo.Migrations.CreateTreasureRoomKeyBZItem do
  use Ecto.Migration

  def up do
    # Create the Treasure Room Key item
    execute """
    INSERT INTO items (
      name,
      description,
      item_type,
      rarity,
      value,
      weight,
      stackable,
      max_stack_size,
      equipment_slot,
      pickup,
      inserted_at,
      updated_at
    ) VALUES (
      'Treasure Room Key',
      'A sturdy iron key etched with the sigil of the treasure room.',
      'key',
      'rare',
      100,
      0.1,
      true,
      1,
      null,
      true,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    execute "DELETE FROM items WHERE name = 'Treasure Room Key';"
  end
end
