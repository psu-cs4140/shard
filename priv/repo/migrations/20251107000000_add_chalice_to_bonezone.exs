defmodule Shard.Repo.Migrations.AddChaliceToBonezone do
  use Ecto.Migration

  def up do
    # First, create the Chalice item if it doesn't exist
    execute """
    INSERT INTO items (
      name,
      description,
      item_type,
      rarity,
      value,
      weight,
      equippable,
      equipment_slot,
      is_active,
      pickup,
      inserted_at,
      updated_at
    ) VALUES (
      'Chalice',
      'An ornate golden chalice adorned with mystical runes. It emanates a faint magical aura and seems to hold ancient power.',
      'misc',
      'rare',
      200,
      1.0,
      false,
      null,
      true,
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING;
    """

    # Then, place the Chalice in the bonezone room at (2,0)
    execute """
    INSERT INTO room_items (
      item_id,
      location,
      quantity,
      inserted_at,
      updated_at
    ) VALUES (
      (SELECT id FROM items WHERE name = 'Chalice' LIMIT 1),
      '2,0,0',
      1,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    # Remove the Chalice from the bonezone room
    execute """
    DELETE FROM room_items 
    WHERE item_id = (SELECT id FROM items WHERE name = 'Chalice' LIMIT 1)
    AND location = '2,0,0';
    """

    # Optionally remove the Chalice item entirely (uncomment if desired)
    # execute "DELETE FROM items WHERE name = 'Chalice';"
  end
end
