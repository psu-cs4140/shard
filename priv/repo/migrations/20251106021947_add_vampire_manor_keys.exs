defmodule Shard.Repo.Migrations.AddVampireManorKeys do
  use Ecto.Migration

  def up do
    # Create the Rusty Sewer Key item and place it in the Courtyard SW (-1,1)
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
      'Rusty Sewer Key',
      'An old, corroded key that looks like it might open a sewer entrance. Despite its rusty appearance, it still seems functional.',
      'key',
      'common',
      10,
      0.1,
      false,
      null,
      true,
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING;
    """

    execute """
    INSERT INTO room_items (
      item_id,
      location,
      quantity,
      inserted_at,
      updated_at
    ) VALUES (
      (SELECT id FROM items WHERE name = 'Rusty Sewer Key' LIMIT 1),
      '1,1,0',
      1,
      NOW(),
      NOW()
    );
    """

    # Create the Manor Key item and place it in the Sewer Lair (-4,1)
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
      'Manor Key',
      'A heavy brass key with intricate engravings. It bears the crest of the vampire manor and unlocks the main entrance.',
      'key',
      'uncommon',
      25,
      0.2,
      false,
      null,
      true,
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING;
    """

    # Create the Library Key item and place it in the Freezer (4,-3)
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
      'Library Key',
      'A small, ornate key made of silver. It has the symbol of an open book etched into its head.',
      'key',
      'uncommon',
      20,
      0.1,
      false,
      null,
      true,
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING;
    """

    # Create the Study Key item and place it in the Library (-1,-2)
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
      'Study Key',
      'A delicate golden key with scholarly symbols carved along its length. It feels warm to the touch.',
      'key',
      'rare',
      35,
      0.1,
      false,
      null,
      true,
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING;
    """

    execute """
    INSERT INTO room_items (
      item_id,
      location,
      quantity,
      inserted_at,
      updated_at
    ) VALUES (
      (SELECT id FROM items WHERE name = 'Study Key' LIMIT 1),
      '-1,-2,0',
      1,
      NOW(),
      NOW()
    );
    """

    # Create the Master Key item and place it in the Freezer (-1,-3)
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
      'Master Key',
      'An imposing black key adorned with crimson gems. It radiates an aura of dark power and authority.',
      'key',
      'legendary',
      100,
      0.3,
      false,
      null,
      true,
      true,
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING;
    """

    execute """
    INSERT INTO room_items (
      item_id,
      location,
      quantity,
      inserted_at,
      updated_at
    ) VALUES (
      (SELECT id FROM items WHERE name = 'Master Key' LIMIT 1),
      '-1,-3,0',
      1,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    # Remove all vampire manor keys from their locations
    execute """
    DELETE FROM room_items 
    WHERE item_id IN (
      SELECT id FROM items WHERE name IN (
        'Rusty Sewer Key',
        'Study Key',
        'Master Key'
      )
    )
    AND location IN ('-1,1,0', '1,1,0', '5,-3,0');
    """

    # Optionally remove the key items entirely (uncomment if desired)
    # execute """
    # DELETE FROM items WHERE name IN (
    #   'Rusty Sewer Key',
    #   'Manor Key', 
    #   'Library Key',
    #   'Study Key',
    #   'Master Key'
    # );
    # """
  end
end
