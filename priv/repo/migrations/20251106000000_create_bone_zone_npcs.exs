defmodule Shard.Repo.Migrations.CreateBoneZoneNpcs do
  use Ecto.Migration

  def up do
    # Insert Tombguard NPC in Bone Zone Room (2,5)
    execute """
    INSERT INTO npcs (
      name,
      description,
      level,
      health,
      max_health,
      mana,
      max_mana,
      strength,
      dexterity,
      intelligence,
      constitution,
      experience_reward,
      gold_reward,
      npc_type,
      dialogue,
      inventory,
      location_x,
      location_y,
      location_z,
      room_id,
      is_active,
      respawn_time,
      faction,
      aggression_level,
      movement_pattern,
      properties,
      inserted_at,
      updated_at
    ) VALUES (
      'Tombguard',
      'A skeletal guardian wearing ancient bone armor, standing watch over the Bone Zone. His hollow eye sockets glow with an eerie blue light as he surveys the area for intruders.',
      15,
      200,
      200,
      100,
      100,
      18,
      14,
      16,
      20,
      150,
      25,
      'quest_giver',
      'Greetings, mortal. I am the Tombguard, protector of these ancient grounds. If you seek passage deeper into the Bone Zone, you must prove your worth through trials.',
      '{}',
      2,
      5,
      0,
      (SELECT id FROM rooms WHERE x_coordinate = 2 AND y_coordinate = 5 LIMIT 1),
      true,
      0,
      'bone_zone_guardians',
      0,
      'stationary',
      '{}',
      NOW(),
      NOW()
    );
    """

    # Create the actual quest records in the database
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
    ) VALUES (
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
    );
    """

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
    ) VALUES (
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
    execute "DELETE FROM quests WHERE giver_npc_id IN (SELECT id FROM npcs WHERE name = 'Tombguard');"
    execute "DELETE FROM npcs WHERE name = 'Tombguard';"
  end
end
