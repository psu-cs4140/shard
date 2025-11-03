defmodule Shard.Repo.Migrations.BackfillExistingRoomsWithDefaultZone do
  use Ecto.Migration

  def up do
    # Create a default "Legacy Map" zone for existing rooms
    execute("""
    INSERT INTO zones (name, slug, description, zone_type, min_level, max_level, is_public, is_active, properties, display_order, inserted_at, updated_at)
    VALUES (
      'Legacy Map',
      'legacy-map',
      'The original game world before the zone system was implemented.',
      'standard',
      1,
      NULL,
      true,
      true,
      '{}',
      0,
      NOW(),
      NOW()
    )
    ON CONFLICT (slug) DO NOTHING
    """)

    # Update all existing rooms without a zone_id to belong to the Legacy Map zone
    execute("""
    UPDATE rooms
    SET zone_id = (SELECT id FROM zones WHERE slug = 'legacy-map')
    WHERE zone_id IS NULL
    """)
  end

  def down do
    # Set zone_id back to NULL for all rooms in Legacy Map
    execute("""
    UPDATE rooms
    SET zone_id = NULL
    WHERE zone_id = (SELECT id FROM zones WHERE slug = 'legacy-map')
    """)

    # Delete the Legacy Map zone
    execute("DELETE FROM zones WHERE slug = 'legacy-map'")
  end
end
