defmodule Shard.Repo.Migrations.CreateTombguardQuests do
  use Ecto.Migration

  def up do
    # Get Tombguard's ID
    tombguard_id_query = """
    SELECT id FROM npcs WHERE name = 'Tombguard' LIMIT 1
    """

    # Insert the three quests for Tombguard
    execute """
    INSERT INTO quests (
      title,
      description,
      quest_type,
      difficulty,
      status,
      min_level,
      max_level,
      experience_reward,
      gold_reward,
      objectives,
      prerequisites,
      giver_npc_id,
      turn_in_npc_id,
      is_active,
      sort_order,
      inserted_at,
      updated_at
    ) VALUES 
    (
      'Retrieve the Scythe of Severing',
      'Seek the lost scythe that slumbers in the Bone Zone’s depths. My oath chains me here, unable to reclaim it. Bring the artifact to me, and your reward shall be a blade touched by the power of the crypt.',
      'fetch',
      'easy',
      'available',
      1,
      20,
      100,
      25,
      '{"retrieve_items": [{"item_name": "Scythe of Severing", "quantity": 1}], "reward_items": [{"item_name": "Spectral Iron Edge", "quantity": 1}]}',
      '{}',
      (SELECT id FROM npcs WHERE name = 'Tombguard' LIMIT 1),
      (SELECT id FROM npcs WHERE name = 'Tombguard' LIMIT 1),
      true,
      1,
      NOW(),
      NOW()
    ),
    (
      'Harvest Spider Silk',
      'Venture forth and slay a spider to collect its silk. This silk is needed for an important ritual. In return, I will grant you a bone zone key that will unlock deeper areas of this realm.',
      'kill',
      'medium',
      'locked',
      5,
      25,
      200,
      50,
      '{"retrieve_items": [{"item_name": "spider silk", "quantity": 1}], "reward_items": [{"item_name": "Bone Zone Key", "quantity": 1}]}',
      '{"completed_quests": ["Retrieve the Scythe of Severing"]}',
      (SELECT id FROM npcs WHERE name = 'Tombguard' LIMIT 1),
      (SELECT id FROM npcs WHERE name = 'Tombguard' LIMIT 1),
      true,
      2,
      NOW(),
      NOW()
    );
    """
  end

  def down do
    execute """
    DELETE FROM quests 
    WHERE title IN (
      'Retrieve the Scythe of Severing',
      'Harvest Spider Silk' 
    );
    """
  end
end
