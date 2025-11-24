defmodule Shard.Repo.Migrations.CreateVampiresThrallNpc do
  use Ecto.Migration

  def up do
    # Insert Vampire's Thrall NPC in Vampire's Manor at Manor Doorstep (0,-1)
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
          'Vampire''s Thrall',
          'A pale, nervous-looking servant bound to the vampire lord. His eyes dart suspiciously, and he clutches a small bundle of keys tightly. Despite his fearful demeanor, he seems willing to help those who might aid him. (Use ''talk "Vampire''''s Thrall"'' to speak with him or ''quest "Vampire''''s Thrall"'' to check for quests)',
      5,
      80,
      80,
      40,
      40,
      8,
      12,
      10,
      10,
      25,
      15,
      'quest_giver',
      'Ah! A visitor to the manor... please, you must help me! My master''''s favorite slippers have been stolen by a foul ooze creature that lurks in the sewers below. I was sent to retrieve them, but I''''m far too frightened to venture down there myself.

    If you can hunt down that disgusting ooze and bring back my master''''s slippers, I''''ll give you the key to enter the manor. Please, it''''s very important - my master will be most displeased if his slippers aren''''t returned!

    The sewer entrance is just to the west of here, though the entrance has been locked for quite some time. The key to it should be buried away somewhere within the garden''''s perimeter to the east. Be careful, adventurer - the sewers are dark and dangerous!',
      '{}',
      0,
      -1,
      0,
      (SELECT r.id FROM rooms r
       JOIN zones z ON r.zone_id = z.id
       WHERE r.x_coordinate = 0 AND r.y_coordinate = -1 AND r.z_coordinate = 0
       AND z.slug = 'vampires-manor' LIMIT 1),
      true,
      0,
      'vampire_manor_servants',
      0,
      'stationary',
      '{
        "quest_available": true,
        "quest_description": "Help the Vampire''''s Thrall retrieve his master''''s stolen slippers from an ooze in the sewers",
        "quest_reward": "Manor Key - allows entry to the main vampire manor",
        "personality": "nervous",
        "background": "indentured servant to vampire lord"
      }',
      NOW(),
      NOW()
    );
    """

    # Insert Gargoyle NPC in Library (-1,-2)
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
          'Gargoyle',
          'A stone gargoyle perched on a pedestal, its eyes glowing with ancient magic. Despite its intimidating appearance, it seems willing to share knowledge with those who approach respectfully. (Use ''talk "Gargoyle"'' to speak with it)',
      8,
      120,
      120,
      60,
      60,
      15,
      8,
      14,
      18,
      0,
      0,
      'informant',
      'Greetings, mortal. I have watched over this manor for centuries, observing all who enter and leave these halls.

    You seek a tomb so powerful, do you not? I can sense your curiosity about the secrets hidden within these walls.
    The key you seek to open the Study... it lies within this manor, yes. 

    From a bird''s eye view, the manor stares at you. 
    On its left, lonesome tip, a tiny glint gives your eyes the slip.
    There, is where your key shall be found.',
      '{}',
      -1,
      -2,
      0,
      (SELECT r.id FROM rooms r
       JOIN zones z ON r.zone_id = z.id
       WHERE r.x_coordinate = 3 AND r.y_coordinate = -2 AND r.z_coordinate = 0
       AND z.slug = 'vampires-manor' LIMIT 1),
      true,
      0,
      'manor_guardians',
      0,
      'stationary',
      '{
        "personality": "ancient_wise",
        "background": "magical guardian of the manor",
        "knowledge_areas": ["manor_layout", "hidden_items", "manor_history"]
      }',
      NOW(),
      NOW()
    );
    """

    # Get Vampire's Thrall ID
    thrall_id_query = """
    SELECT id FROM npcs WHERE name = 'Vampire''s Thrall' LIMIT 1
    """

    # Create the quest for retrieving the slippers
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
      'The Master''s Slippers',
      'The Vampire''s Thrall needs you to retrieve his master''s stolen slippers from a sewage slime in the sewer lair. The slippers were taken by a disgusting ooze creature that lurks in the depths below the manor.',
      'fetch',
      'easy',
      'available',
      1,
      10,
      50,
      25,
      '{"retrieve_items": [{"item_name": "Slippers", "quantity": 1}], "reward_items": [{"item_name": "Manor Key", "quantity": 1}]}',
      '{}',
      (SELECT id FROM npcs WHERE name = 'Vampire''s Thrall' LIMIT 1),
      (SELECT id FROM npcs WHERE name = 'Vampire''s Thrall' LIMIT 1),
      true,
      1,
      NOW(),
      NOW()
    );
    """

    # Insert The Mayor NPC in Cellar (-2,-4)
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
          'The Mayor',
          'A distinguished elderly man in tattered formal attire, looking relieved but weary from his ordeal. His eyes light up with gratitude when he sees you. (Use ''talk "The Mayor"'' to speak with him)',
      3,
      50,
      50,
      20,
      20,
      6,
      8,
      12,
      8,
      0,
      0,
      'civilian',
      'Oh, thank the heavens! You''ve come to rescue me! I am the Mayor of the nearby village, and I was captured by that dreadful vampire lord while investigating reports of missing villagers.

    I cannot express how grateful I am for your bravery in venturing into this cursed place to find me. The Count had been holding me prisoner down here in this dank cellar, planning some terrible fate for me.

    You are truly a hero! When we return to the village, I shall ensure that your heroic deeds are celebrated by all. The people will sing songs of your courage for generations to come!

    Please, lead me out of this nightmare. I never want to see this accursed manor again!',
      '{}',
      -2,
      -4,
      0,
      (SELECT r.id FROM rooms r
       JOIN zones z ON r.zone_id = z.id
       WHERE r.x_coordinate = -2 AND r.y_coordinate = -4 AND r.z_coordinate = 0
       AND z.slug = 'vampires-manor' LIMIT 1),
      true,
      0,
      'village_officials',
      0,
      'stationary',
      '{
        "personality": "grateful_dignified",
        "background": "village mayor captured by vampires",
        "rescue_status": "awaiting_rescue"
      }',
      NOW(),
      NOW()
    );
    """
  end

  def down do
    execute "DELETE FROM quests WHERE title = 'The Master''s Slippers';"
    execute "DELETE FROM npcs WHERE name = 'Vampire''s Thrall';"
    execute "DELETE FROM npcs WHERE name = 'Gargoyle';"
    execute "DELETE FROM npcs WHERE name = 'The Mayor';"
  end
end
