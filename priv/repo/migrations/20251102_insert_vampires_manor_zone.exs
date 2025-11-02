defmodule Shard.Repo.Migrations.InsertVampiresManorZone do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO zones (name, slug, description, zone_type, min_level, max_level, is_public, is_active, properties, display_order, inserted_at, updated_at)
    VALUES (
      'The Vampire''s Manor',
      'the-vampires-manor',
      'A mysterious manor in the middle of the marshlands. There''s a haunting air to it.',
      'standard',
      1,
      NULL,
      true,
      true,
      '{}',
      0,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    execute """
    DELETE FROM zones WHERE slug = 'the-vampires-manor';
    """
  end
end
