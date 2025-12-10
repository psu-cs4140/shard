defmodule Shard.Repo.Migrations.AddCreateFirstCharacterAchievement do
  use Ecto.Migration

  def up do
    # Insert the "Create First Character" achievement (skip if already exists)
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
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "Enter Beginner Bone Zone" achievement (skip if already exists)
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
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "Enter Vampire Manor" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'Enter Vampire Manor',
      'Dare to enter the mysterious Vampire Manor',
      'vampire-icon',
      'exploration',
      20,
      false,
      '{"type": "zone_entered", "zone": "Vampire''s Manor"}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "Enter Mines" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'Enter Mines',
      'Descend into the depths of the Mines',
      'pickaxe-icon',
      'exploration',
      20,
      false,
      '{"type": "zone_entered", "zone": "Mines"}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "Enter Whispering Forest" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'Enter Whispering Forest',
      'Step into the mystical Whispering Forest',
      'tree-icon',
      'exploration',
      20,
      false,
      '{"type": "zone_entered", "zone": "Whispering Forest"}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "GEMS!" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'GEMS!',
      'Find your first precious gemstone while mining',
      'gem-icon',
      'mining',
      25,
      false,
      '{"type": "mining_resource_obtained", "resource": "gem", "count": 1}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "Acquiring Lumber" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'Acquiring Lumber',
      'Chop your first piece of wood in the forest',
      'wood-icon',
      'chopping',
      20,
      false,
      '{"type": "chopping_resource_obtained", "resource": "wood", "count": 1}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "A Hint of Prehistoric Life" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'A Hint of Prehistoric Life',
      'Discover your first ancient resin while chopping in the forest',
      'amber-icon',
      'chopping',
      30,
      false,
      '{"type": "chopping_resource_obtained", "resource": "resin", "count": 1}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "Lucky Gambler" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'Lucky Gambler',
      'Win your first coin flip bet',
      'coin-icon',
      'gambling',
      15,
      false,
      '{"type": "gambling_bet_won", "count": 1}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "Learning Experience" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'Learning Experience',
      'Lose your first coin flip bet - every gambler learns the hard way',
      'broken-coin-icon',
      'gambling',
      10,
      false,
      '{"type": "gambling_bet_lost", "count": 1}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "Entering the Stone Age" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'Entering the Stone Age',
      'Mine your first piece of stone and begin your journey into civilization',
      'stone-icon',
      'mining',
      15,
      false,
      '{"type": "mining_resource_obtained", "resource": "stone", "count": 1}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
    """

    # Insert the "First Blood" achievement (skip if already exists)
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'First Blood',
      'Defeat your first monster in combat',
      'sword-icon',
      'combat',
      20,
      false,
      '{"type": "monster_killed", "count": 1}',
      NOW(),
      NOW()
    )
    ON CONFLICT (name) DO NOTHING
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
    DELETE FROM achievements WHERE name IN ('Create First Character', 'Enter Beginner Bone Zone', 'Enter Vampire Manor', 'Enter Mines', 'Enter Whispering Forest', 'GEMS!', 'Acquiring Lumber', 'A Hint of Prehistoric Life', 'Lucky Gambler', 'Learning Experience', 'Entering the Stone Age', 'First Blood')
    """
  end
end
