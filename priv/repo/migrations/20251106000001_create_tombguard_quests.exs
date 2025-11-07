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
      short_description,
      quest_type,
      difficulty,
      min_level,
      max_level,
      experience_reward,
      gold_reward,
      item_rewards,
      prerequisites,
      objectives,
      status,
      is_repeatable,
      giver_npc_id,
      turn_in_npc_id,
      location_hint,
      is_active,
      sort_order,
      properties,
      inserted_at,
      updated_at
    ) VALUES 
    (
      'Retrieve the Iron Sword',
      'Travel to the barracks and retrieve the iron sword that lies within. Bring it back to me as proof of your courage.',
      'Find and retrieve the iron sword from the barracks',
      'main',
      'normal',
      1,
      NULL,
      100,
      50,
      '{}',
      '{}',
      '{"retrieve_items": [{"item_name": "Iron Sword", "quantity": 1}]}',
      'available',
      false,
      (#{tombguard_id_query}),
      (#{tombguard_id_query}),
      'Look for the barracks in the Bone Zone',
      true,
      1,
      '{"quest_chain_step": 1, "next_quest": "kill_spider"}',
      NOW(),
      NOW()
    ),
    (
      'Harvest Spider Silk',
      'Venture forth and slay a spider to collect its silk. This silk is needed for an important ritual.',
      'Kill a spider and bring back spider silk',
      'main',
      'normal',
      1,
      NULL,
      150,
      75,
      '{}',
      '{"completed_quests": ["Retrieve the Iron Sword"]}',
      '{"retrieve_items": [{"item_name": "Spider Silk", "quantity": 1}]}',
      'locked',
      false,
      (#{tombguard_id_query}),
      (#{tombguard_id_query}),
      'Spiders can be found throughout the Bone Zone',
      true,
      2,
      '{"quest_chain_step": 2, "next_quest": "receive_key", "prerequisite": "retrieve_sword"}',
      NOW(),
      NOW()
    ),
    (
      'Receive the Bone Zone Key',
      'Return to Tombguard with the spider silk to receive the Bone Zone key.',
      'Deliver spider silk to Tombguard',
      'main',
      'normal',
      1,
      NULL,
      200,
      100,
      '{"bone_zone_key": 1}',
      '{"completed_quests": ["Harvest Spider Silk"]}',
      '{"retrieve_items": [{"item_name": "Spider Silk", "quantity": 1}]}',
      'locked',
      false,
      (#{tombguard_id_query}),
      (#{tombguard_id_query}),
      'Return to Tombguard at coordinates (2,5)',
      true,
      3,
      '{"quest_chain_step": 3, "prerequisite": "kill_spider", "final_quest": true}',
      NOW(),
      NOW()
    );
    """
  end

  def down do
    execute """
    DELETE FROM quests 
    WHERE title IN (
      'Retrieve the Iron Sword',
      'Harvest Spider Silk', 
      'Receive the Bone Zone Key'
    );
    """
  end
end
