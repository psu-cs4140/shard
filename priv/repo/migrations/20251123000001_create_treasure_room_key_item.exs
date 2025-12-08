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
    )
    ON CONFLICT (name) DO NOTHING;
    """

    # Then, place the Key in the bonezone room at (2,0)
    execute """
    INSERT INTO room_items (
      item_id,
      location,
      quantity,
      inserted_at,
      updated_at
    ) VALUES (
      (SELECT id FROM items WHERE name = 'Treasure Room Key' LIMIT 1),
      '5,4,0',
      1,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    # Remove the Treasure Room Key from the bonezone room
    execute """
    DELETE FROM room_items
    WHERE item_id = (SELECT id FROM items WHERE name = 'Treasure Room Key' LIMIT 1)
    AND location = '2,0,0';
    """

    # Optionally remove the Treasure Room Key item entirely (uncomment if desired)
    # execute "DELETE FROM items WHERE name = 'Treasure Room Key';"
  end
end
