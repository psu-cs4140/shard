defmodule Shard.Repo.Migrations.AddCreateFirstCharacterAchievement do
  use Ecto.Migration

  def up do
    # Insert the "Create First Character" achievement
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'Create First Character',
      'Create your first character to begin your adventure',
      'character-icon',
      'getting_started',
      10,
      false,
      '{"type": "character_created", "count": 1}',
      NOW(),
      NOW()
    )
    """

    # Insert the "Enter Beginner Bone Zone" achievement
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'Enter Beginner Bone Zone',
      'Take your first steps into the Beginner Bone Zone',
      'zone-icon',
      'exploration',
      15,
      false,
      '{"type": "zone_entered", "zone": "Beginner Bone Zone"}',
      NOW(),
      NOW()
    )
    """

    # Award the achievement to users who already have characters
    execute """
    INSERT INTO user_achievements (user_id, achievement_id, earned_at, progress, inserted_at, updated_at)
    SELECT DISTINCT 
      c.user_id,
      a.id,
      NOW(),
      '{"characters_created": 1}'::jsonb,
      NOW(),
      NOW()
    FROM characters c
    CROSS JOIN achievements a
    WHERE a.name = 'Create First Character'
    AND NOT EXISTS (
      SELECT 1 FROM user_achievements ua 
      WHERE ua.user_id = c.user_id 
      AND ua.achievement_id = a.id
    )
    """
  end

  def down do
    # Remove user achievements for this achievement
    execute """
    DELETE FROM user_achievements 
    WHERE achievement_id IN (
      SELECT id FROM achievements WHERE name = 'Create First Character'
    )
    """

    # Remove the achievements
    execute """
    DELETE FROM achievements WHERE name IN ('Create First Character', 'Enter Beginner Bone Zone')
    """
  end
end
