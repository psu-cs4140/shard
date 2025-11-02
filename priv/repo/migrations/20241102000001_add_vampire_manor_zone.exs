defmodule Shard.Repo.Migrations.AddVampireManorZone do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO zones (name, slug, description, zone_type, min_level, max_level, is_public, inserted_at, updated_at)
    VALUES (
      'The Vampire''s Manor',
      'vampire-manor',
      'A dark and foreboding manor house shrouded in perpetual mist. Ancient stone walls are covered in creeping ivy, and the windows glow with an eerie red light. The air is thick with the scent of decay and old blood.',
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
    DELETE FROM zones WHERE slug = 'vampire-manor';
    """
  end
end
