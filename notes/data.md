# Notes for Data Design and DB Schema

__Authors:__ _Erica Guenther and Tyler Smallidge_

### <u>__Data Design__</u>
For our multi-user dungeion, we should use a relational database like MySQL which we used in our Database Management Systems class. This will allow us to manage all of the interconnect parts of our game. Additionally, we made sure to create tables that incorporate all the ideas from rpg-mechanics.md

### <u>__DB Schema__</u> <br/>
__Important Entities/Tables__ 
<br /> ~ <u>_Player_</u> 
<br />&nbsp;&nbsp;&nbsp; - player_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - username
<br />&nbsp;&nbsp;&nbsp; - password_hash
<br />&nbsp;&nbsp;&nbsp; - email
<br />&nbsp;&nbsp;&nbsp; - date_created

~ <u>_Character_</u>
<br />&nbsp;&nbsp;&nbsp; - character_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - player_id (FOREIGN KEY referencing Player)
<br />&nbsp;&nbsp;&nbsp; - character_name
<br />&nbsp;&nbsp;&nbsp; - level
<br />&nbsp;&nbsp;&nbsp; - experience_points
<br />&nbsp;&nbsp;&nbsp; - health
<br />&nbsp;&nbsp;&nbsp; - current_room_id (FOREIGN KEY referencing Room)
<br />&nbsp;&nbsp;&nbsp; - inventory_id (FOREIGN KEY referencing Inventory)

~ <u>_Monster_</u>
<br />&nbsp;&nbsp;&nbsp; - monster_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - monster_name
<br />&nbsp;&nbsp;&nbsp; - level (easy, medium, hard, boss, etc.)
<br />&nbsp;&nbsp;&nbsp; - experience_points (from defeating it)
<br />&nbsp;&nbsp;&nbsp; - health
<br />&nbsp;&nbsp;&nbsp; - attack
<br />&nbsp;&nbsp;&nbsp; - defense
<br />&nbsp;&nbsp;&nbsp; - current_room_id (FOREIGN KEY referencing Room)
<br />&nbsp;&nbsp;&nbsp; - item_drop (FOREIGN KEY referencing Item, what it drops when killed)
<br />&nbsp;&nbsp;&nbsp; - monster_effects (FOREIGN KEY referencing Effects, what effects it can put on a character)

~ <u>_Room_</u>
<br />&nbsp;&nbsp;&nbsp; - room_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - room_name
<br />&nbsp;&nbsp;&nbsp; - description

~ <u>_Exit_</u>
<br />&nbsp;&nbsp;&nbsp; - exit_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - from_room_id (FOREIGN KEY referencing Room)
<br />&nbsp;&nbsp;&nbsp; - to_room_id (FOREIGN KEY referencing Room)
<br />&nbsp;&nbsp;&nbsp; - direction

~ <u>_Currency_</u>
<br />&nbsp;&nbsp;&nbsp; - character_id (PRIMARY KEY and FOREIGN KEY to Character)
<br />&nbsp;&nbsp;&nbsp; - gold_coins
<br />&nbsp;&nbsp;&nbsp; - silver_coins
<br />&nbsp;&nbsp;&nbsp; - copper_coins

~ <u>_Items_</u>
<br />&nbsp;&nbsp;&nbsp; - item_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - item_name
<br />&nbsp;&nbsp;&nbsp; - description
<br />&nbsp;&nbsp;&nbsp; - type (e.g. weapon, accessory, etc.)
<br />&nbsp;&nbsp;&nbsp; - value (how much it's worth/costs)

~ <u>_Inventory_</u>
<br />&nbsp;&nbsp;&nbsp; - inventory_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - character_id (FOREIGN KEY referencing Character)
<br />&nbsp;&nbsp;&nbsp; - item_id (FOREIGN KEY referencing Item)
<br />&nbsp;&nbsp;&nbsp; - quantity 

~ <u>_NPC_</u>
<br />&nbsp;&nbsp;&nbsp; - npc_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - npc_name
<br />&nbsp;&nbsp;&nbsp; - description
<br />&nbsp;&nbsp;&nbsp; - current_room_id (FOREIGN KEY referencing Room)
<br />&nbsp;&nbsp;&nbsp; - dialogue

~ <u>_Quest_</u> 
<br />&nbsp;&nbsp;&nbsp; - quest_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - npc_id (FOREIGN KEY referencing NPC - who gives the quest out) 
<br />&nbsp;&nbsp;&nbsp; - quest_name
<br />&nbsp;&nbsp;&nbsp; - description
<br />&nbsp;&nbsp;&nbsp; - reward

~ <u>_Character_Quest_</u>
<br />&nbsp;&nbsp;&nbsp; - character_id (FOREIGN KEY referencing Character)
<br />&nbsp;&nbsp;&nbsp; - quest_id (FOREIGN KEY referencing Quest)
<br />&nbsp;&nbsp;&nbsp; - status
<br />&nbsp;&nbsp;&nbsp; - PRIMARY KEY (character_id, quest_id)

~ <u>_Skills_</u>
<br />&nbsp;&nbsp;&nbsp; - skill_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - skill_name
<br />&nbsp;&nbsp;&nbsp; - description
<br />&nbsp;&nbsp;&nbsp; - type (e.g. healing, combat, magic, etc.)
<br />&nbsp;&nbsp;&nbsp; - max_level

~ <u>_Character_Skills_</u>
<br />&nbsp;&nbsp;&nbsp; - character_id (FOREIGN KEY referencing Character)
<br />&nbsp;&nbsp;&nbsp; - skill_id (FOREIGN KEY referencing Skill)
<br />&nbsp;&nbsp;&nbsp; - skill_level
<br />&nbsp;&nbsp;&nbsp; - experience points
<br />&nbsp;&nbsp;&nbsp; - PRIMARY KEY (character_id, skill_id)

~ <u>_Spells_</u>
<br />&nbsp;&nbsp;&nbsp; - spell_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - spell_name
<br />&nbsp;&nbsp;&nbsp; - description
<br />&nbsp;&nbsp;&nbsp; - cooldown_time

~ <u>_Character_Spells_</u>
<br />&nbsp;&nbsp;&nbsp; - character_id (FOREIGN KEY referencing Character)
<br />&nbsp;&nbsp;&nbsp; - spell_id (FOREIGN KEY referencing Spell)
<br />&nbsp;&nbsp;&nbsp; - last_cast (for cooldown time)
<br />&nbsp;&nbsp;&nbsp; - PRIMARY KEY (character_id, spell_id)

~ <u>_Consumables_</u>
<br />&nbsp;&nbsp;&nbsp; - consumable_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - consumable_name
<br />&nbsp;&nbsp;&nbsp; - description
<br />&nbsp;&nbsp;&nbsp; - consumable_type (food, herb, potion, etc.)
<br />&nbsp;&nbsp;&nbsp; - cost
<br />&nbsp;&nbsp;&nbsp; - effect_id (FOREIGN KEY referencing Effect)

~ <u>_Character_Consumables_</u>
<br />&nbsp;&nbsp;&nbsp; - character_id (FOREIGN KEY referencing Character)
<br />&nbsp;&nbsp;&nbsp; - consumable_id (FOREIGN KEY referencing Consumables)
<br />&nbsp;&nbsp;&nbsp; - quantity (how many a character has)
<br />&nbsp;&nbsp;&nbsp; - PRIMARY KEY (character_id, consumable_id)

~ <u>_Effects_</u>
<br />&nbsp;&nbsp;&nbsp; - effect_id (PRIMARY KEY)
<br />&nbsp;&nbsp;&nbsp; - effect_name
<br />&nbsp;&nbsp;&nbsp; - description
<br />&nbsp;&nbsp;&nbsp; - duration
<br />&nbsp;&nbsp;&nbsp; - status_conditions (healing, poison, blinded, etc.)

~ <u>_Character_Effects_</u>
<br />&nbsp;&nbsp;&nbsp; - character_id (FOREIGN KEY referencing Character)
<br />&nbsp;&nbsp;&nbsp; - effect_id (FOREIGN KEY referencing Effect)
<br />&nbsp;&nbsp;&nbsp; - start_time (to calculate how long is left)
<br />&nbsp;&nbsp;&nbsp; - duration
<br />&nbsp;&nbsp;&nbsp; - magnitude (how much it does, e.g. +5 strength, -5 health)
<br />&nbsp;&nbsp;&nbsp; - stackable (TRUE/FALSE - is more than one effect of this type applied)
<br />&nbsp;&nbsp;&nbsp; - PRIMARY KEY (character_id, effect_id)

__Advanced Tables to Possibly Add__ <br /> ~ <u>_Clans/Guilds_</u> - if players want to form groups <br /> ~ <u>_World State_</u> - tables to track world changes, such as a certain monster died or if items inside a chest were taken, etc.
