defmodule Shard.Repo.Migrations.AddIronSwordToBarracks do
  use Ecto.Migration

  def up do
    # First, create the Iron Sword item if it doesn't exist
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
      'Iron Sword',
      'A well-crafted iron sword with a sharp blade and sturdy hilt. This ancient weapon has seen many battles but remains reliable.',
      'weapon',
      'common',
      50,
      3.5,
      true,
      'weapon',
      true,
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING;
    """

    # Then, place the Iron Sword in the barracks room at (7,3)
    execute """
    INSERT INTO room_items (
      item_id,
      location,
      quantity,
      inserted_at,
      updated_at
    ) VALUES (
      (SELECT id FROM items WHERE name = 'Iron Sword' LIMIT 1),
      '7,3,0',
      1,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    # Remove the Iron Sword from the barracks room
    execute """
    DELETE FROM room_items 
    WHERE item_id = (SELECT id FROM items WHERE name = 'Iron Sword' LIMIT 1)
    AND location = '7,3,0';
    """

    # Optionally remove the Iron Sword item entirely (uncomment if desired)
    # execute "DELETE FROM items WHERE name = 'Iron Sword';"
  end
end
