defmodule Shard.Repo.Migrations.AddGrimScytheAchievement do
  use Ecto.Migration

  def up do
    # Insert the "What, did Grim lose this?" achievement
    execute """
    INSERT INTO achievements (name, description, icon, category, points, hidden, requirements, inserted_at, updated_at)
    VALUES (
      'What, did Grim lose this?',
      'Complete the quest to retrieve the Scythe of Severing for the Tombguard',
      'scythe-icon',
      'quests',
      25,
      false,
      '{"type": "quest_completed", "quest": "Retrieve the Scythe of Severing"}',
      NOW(),
      NOW()
    )
    """

    # Award the achievement to users who have already completed the quest
    execute """
    INSERT INTO user_achievements (user_id, achievement_id, earned_at, progress, inserted_at, updated_at)
    SELECT DISTINCT 
      qa.user_id,
      a.id,
      qa.completed_at,
      '{"quest_completed": "Retrieve the Scythe of Severing"}'::jsonb,
      NOW(),
      NOW()
    FROM quest_acceptances qa
    JOIN quests q ON qa.quest_id = q.id
    CROSS JOIN achievements a
    WHERE q.title = 'Retrieve the Scythe of Severing'
    AND qa.status = 'completed'
    AND a.name = 'What, did Grim lose this?'
    AND NOT EXISTS (
      SELECT 1 FROM user_achievements ua 
      WHERE ua.user_id = qa.user_id 
      AND ua.achievement_id = a.id
    )
    """
  end

  def down do
    # Remove user achievements for this achievement
    execute """
    DELETE FROM user_achievements 
    WHERE achievement_id IN (
      SELECT id FROM achievements WHERE name = 'What, did Grim lose this?'
    )
    """

    # Remove the achievement
    execute """
    DELETE FROM achievements WHERE name = 'What, did Grim lose this?'
    """
  end
end
