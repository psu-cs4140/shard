defmodule Shard.Repo.Migrations.CreateMinesZone do
  use Ecto.Migration

  def up do
    # Create the Mines zone
    execute """
    INSERT INTO zones (name, slug, description, zone_type, min_level, max_level, is_public, is_active, display_order, properties, inserted_at, updated_at)
    VALUES (
      'Mines',
      'mines',
      'Venture into the abandoned mines to gather valuable resources. Strike your pickaxe and collect stone, coal, copper ore, iron ore, and rare gems.',
      'wilderness',
      1,
      NULL,
      true,
      true,
      100,
      '{"allow_mining": true}',
      NOW(),
      NOW()
    )
    ON CONFLICT (slug) DO NOTHING
    """

    # Create a simple mining area room for the Mines zone
    execute """
    INSERT INTO rooms (name, description, x_coordinate, y_coordinate, z_coordinate, zone_id, inserted_at, updated_at)
    SELECT
      'Mining Cavern',
      'A vast underground cavern filled with mineral deposits. The walls glitter with ore veins, and your pickaxe echoes as you work. You can start mining here to gather resources.',
      0,
      0,
      0,
      z.id,
      NOW(),
      NOW()
    FROM zones z
    WHERE z.slug = 'mines'
    ON CONFLICT DO NOTHING
    """

    # Create the Whispering Forest zone
    execute """
    INSERT INTO zones (name, slug, description, zone_type, min_level, max_level, is_public, is_active, display_order, properties, inserted_at, updated_at)
    VALUES (
      'Whispering Forest',
      'whispering_forest',
      'A serene forest filled with towering pines and hidden resources for skilled woodcutters.',
      'wilderness',
      1,
      NULL,
      true,
      true,
      101,
      '{"allow_chopping": true}',
      NOW(),
      NOW()
    )
    ON CONFLICT (slug) DO NOTHING
    """

    execute """
    INSERT INTO rooms (name, description, x_coordinate, y_coordinate, z_coordinate, zone_id, inserted_at, updated_at)
    SELECT
      'Forest Clearing',
      'A peaceful clearing where the sound of axes rings through the trees. You can start chopping here to gather wood and other resources.',
      0,
      0,
      0,
      z.id,
      NOW(),
      NOW()
    FROM zones z
    WHERE z.slug = 'whispering_forest'
    ON CONFLICT DO NOTHING
    """
  end

  def down do
    # Remove the mining room
    execute """
    DELETE FROM rooms
    WHERE zone_id IN (SELECT id FROM zones WHERE slug = 'mines')
    """

    # Remove the Mines zone
    execute "DELETE FROM zones WHERE slug = 'mines'"

    execute """
    DELETE FROM rooms
    WHERE zone_id IN (SELECT id FROM zones WHERE slug = 'whispering_forest')
    """

    execute "DELETE FROM zones WHERE slug = 'whispering_forest'"
  end
end
