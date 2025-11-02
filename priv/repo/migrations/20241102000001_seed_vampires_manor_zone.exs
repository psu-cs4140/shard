defmodule Shard.Repo.Migrations.SeedVampiresManorZone do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO zones (name, slug, description, zone_type, min_level, max_level, is_public, inserted_at, updated_at)
    VALUES (
      'The Vampire''s Manor',
      'vampires-manor',
      'A dark and foreboding manor house shrouded in mist and mystery. Ancient stone walls are covered in ivy, and the windows glow with an eerie red light. The air is thick with the scent of decay and old blood.',
      'dungeon',
      15,
      25,
      true,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    execute """
    DELETE FROM zones WHERE slug = 'vampires-manor';
    """
  end
end
