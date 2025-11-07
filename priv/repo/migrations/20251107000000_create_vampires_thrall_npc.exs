defmodule Shard.Repo.Migrations.CreateVampiresThrallNpc do
  use Ecto.Migration

  def up do
    # Insert Vampire's Thrall NPC in Vampire's Manor at Manor Doorstep (0,-1)
    # Only insert if the NPC doesn't already exist
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
)
SELECT
  'Vampire''s Thrall',
  'A pale, nervous-looking servant bound to the vampire lord. His eyes dart suspiciously, and he clutches a small bundle of keys tightly. Despite his fearful demeanor, he seems willing to help those who might aid him. (Use ''talk "Vampire''s Thrall"'' to speak with him or ''quest "Vampire''s Thrall"'' to check for quests)',
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
  'Ah! A visitor to the manor... please, you must help me! My master''s favorite slippers have been stolen by a foul ooze creature that lurks in the sewers below. I was sent to retrieve them, but I''m far too frightened to venture down there myself.

If you can hunt down that disgusting ooze and bring back my master''s slippers, I''ll give you the key to enter the manor. Please, it''s very important - my master will be most displeased if his slippers aren''t returned!

The sewer entrance is just to the west of here. Be careful, adventurer - the sewers are dark and dangerous!',
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
    "quest_description": "Help the Vampire''s Thrall retrieve his master''s stolen slippers from an ooze in the sewers",
    "quest_reward": "Manor Key - allows entry to the main vampire manor",
    "personality": "nervous",
    "background": "indentured servant to vampire lord"
  }',
  NOW(),
  NOW()
WHERE NOT EXISTS (
  SELECT 1 FROM npcs WHERE name = 'Vampire''s Thrall'
);
"""
  end

  def down do
    execute "DELETE FROM npcs WHERE name = 'Vampire''s Thrall';"
  end
end
