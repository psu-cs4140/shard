defmodule Shard.Repo.Migrations.CreateTutorialNpcs do
  use Ecto.Migration

  def up do
    # Create tutorial NPCs that will be shared across all users
    execute """
    INSERT INTO npcs (
      name, description, level, health, max_health, mana, max_mana,
      strength, dexterity, intelligence, constitution, experience_reward,
      gold_reward, npc_type, dialogue, location_x, location_y, location_z,
      is_active, faction, aggression_level, movement_pattern,
      inserted_at, updated_at
    ) VALUES
    (
      'Elder Sage Throne',
      'An ancient wizard with a long white beard, wearing flowing robes. His eyes twinkle with wisdom and magical knowledge.',
      50, 200, 200, 500, 500, 15, 20, 45, 25, 1000, 100,
      'quest_giver',
      '{"greeting": "Welcome, young adventurer! I have been expecting you. The realm needs heroes like yourself.", "quest_offer": "I have an important task for you. Will you help protect our lands?", "farewell": "May the winds guide your path, brave one."}',
      1, 1, 0, true, 'neutral', 0, 'stationary',
      NOW(), NOW()
    ),
    (
      'Captain Marcus',
      'A seasoned warrior in polished armor, standing guard with a gleaming sword at his side. His stern expression shows years of battle experience.',
      35, 400, 400, 100, 100, 40, 25, 15, 35, 750, 75,
      'trainer',
      '{"greeting": "Greetings, recruit! Ready to learn the ways of combat?", "training_offer": "I can teach you sword techniques and battle tactics.", "farewell": "Remember - discipline and honor above all!"}',
      3, 1, 0, true, 'alliance', 1, 'patrol',
      NOW(), NOW()
    ),
    (
      'Merchant Elara',
      'A cheerful halfling trader with a pack full of goods. Her cart is loaded with potions, weapons, and various adventuring supplies.',
      20, 150, 150, 200, 200, 10, 30, 25, 20, 300, 50,
      'merchant',
      '{"greeting": "Hello there! Looking for some fine wares?", "shop_offer": "I have the best prices in all the land! Take a look at my goods.", "farewell": "Safe travels, and come back anytime!"}',
      1, 3, 0, true, 'neutral', 0, 'stationary',
      NOW(), NOW()
    ),
    (
      'Forest Guardian Lyra',
      'A mystical elf ranger with emerald eyes and bark-like skin. She moves silently through the forest, protecting nature from harm.',
      40, 300, 300, 250, 250, 25, 35, 30, 28, 800, 80,
      'guardian',
      '{"greeting": "The forest whispers of your arrival, traveler.", "warning": "Respect the natural balance, and nature will aid you.", "farewell": "May the trees shelter you on your journey."}',
      2, 2, 0, true, 'nature', 3, 'wander',
      NOW(), NOW()
    );
    """
  end

  def down do
    execute """
    DELETE FROM npcs WHERE name IN (
      'Elder Sage Throne',
      'Captain Marcus', 
      'Merchant Elara',
      'Forest Guardian Lyra'
    );
    """
  end
end
