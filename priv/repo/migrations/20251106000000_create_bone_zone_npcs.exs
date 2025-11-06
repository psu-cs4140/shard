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
      '{
        "quest_chain": {
          "current_quest": "retrieve_sword",
          "completed_quests": [],
          "available_quests": ["retrieve_sword", "kill_spider", "receive_key"]
        },
        "quest_retrieve_sword": {
          "name": "Retrieve the Ancient Sword",
          "description": "Travel to the barracks and retrieve the ancient sword that lies within. Bring it back to me as proof of your courage.",
          "objective": "Find and retrieve the ancient sword from the barracks",
          "reward": "Access to the next trial",
          "status": "available"
        },
        "quest_kill_spider": {
          "name": "Harvest Spider Silk",
          "description": "Venture forth and slay a spider to collect its silk. This silk is needed for an important ritual.",
          "objective": "Kill a spider and bring back spider silk",
          "reward": "The Bone Zone key",
          "status": "locked",
          "prerequisite": "retrieve_sword"
        },
        "quest_receive_key": {
          "name": "Receive the Bone Zone Key",
          "description": "Return to Tombguard with the spider silk to receive the Bone Zone key.",
          "objective": "Deliver spider silk to Tombguard",
          "reward": "Bone Zone key and access to deeper areas",
          "status": "locked",
          "prerequisite": "kill_spider"
        }
      }',
      NOW(),
      NOW()
    );
    """
  end

  def down do
    execute "DELETE FROM npcs WHERE name = 'Tombguard';"
  end
end
