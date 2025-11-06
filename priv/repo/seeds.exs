# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Shard.Repo.insert!(%Shard.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query

alias Shard.Repo
alias Shard.Map.{Room, Door}

# Check if rooms already exist to avoid duplication
room_count = Repo.aggregate(Room, :count, :id)

if room_count == 0 do
  # Create a 3x3 grid of rooms (9 total)
  rooms =
    for x <- 0..2, y <- 0..2 do
      %{
        name: "Room (#{x},#{y})",
        description: "A room in the grid at coordinates (#{x},#{y})",
        x_coordinate: x,
        y_coordinate: y,
        is_public: true,
        room_type: "standard"
      }
    end
    |> Enum.map(&Repo.insert!(%Room{} |> Room.changeset(&1)))

  # Create doors between adjacent rooms
  # Connect horizontally (east-west)
  for x <- 0..1, y <- 0..2 do
    from_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
    to_room = Enum.find(rooms, &(&1.x_coordinate == x + 1 && &1.y_coordinate == y))

    # Door from left room to right room (east)
    Repo.insert!(
      %Door{}
      |> Door.changeset(%{
        from_room_id: from_room.id,
        to_room_id: to_room.id,
        direction: "east",
        door_type: "standard",
        is_locked: false,
        properties: %{"state" => "open"}
      })
    )

    # Door from right room to left room (west)
    Repo.insert!(
      %Door{}
      |> Door.changeset(%{
        from_room_id: to_room.id,
        to_room_id: from_room.id,
        direction: "west",
        door_type: "standard",
        is_locked: false,
        properties: %{"state" => "open"}
      })
    )
  end

  # Connect vertically (north-south)
  for x <- 0..2, y <- 0..1 do
    from_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
    to_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y + 1))

    # Door from bottom room to top room (north)
    Repo.insert!(
      %Door{}
      |> Door.changeset(%{
        from_room_id: from_room.id,
        to_room_id: to_room.id,
        direction: "north",
        door_type: "standard",
        is_locked: false,
        properties: %{"state" => "open"}
      })
    )

    # Door from top room to bottom room (south)
    Repo.insert!(
      %Door{}
      |> Door.changeset(%{
        from_room_id: to_room.id,
        to_room_id: from_room.id,
        direction: "south",
        door_type: "standard",
        is_locked: false,
        properties: %{"state" => "open"}
      })
    )
  end

  IO.puts("Created 3x3 grid of rooms with connecting doors")
else
  IO.puts("Rooms already exist in the database, skipping grid creation")
end

# Weapon-related seed data
alias Shard.Weapons.{
  Weapons,
  Classes,
  DamageTypes,
  Effects,
  Enchantments,
  Rarities,
  WeaponEffects,
  WeaponEnchantments
}

# Seed data modules
alias Shard.Weapons.SeedData.{
  WeaponsSeeds,
  ClassesSeeds,
  DamageTypesSeeds,
  EffectsSeeds,
  EnchantmentsSeeds,
  RaritiesSeeds,
  WeaponEffectsSeeds,
  WeaponEnchantmentsSeeds
}

# Check if damage types exist
damage_type_count = Repo.aggregate(DamageTypes, :count, :id)

if damage_type_count == 0 do
  DamageTypesSeeds.data()
  |> Enum.each(fn damage_type ->
    Repo.insert!(%DamageTypes{} |> DamageTypes.changeset(damage_type))
  end)

  IO.puts("Seeded damage types")
else
  IO.puts("Damage types already exist, skipping seeding")
end

# Check if rarities exist
rarity_count = Repo.aggregate(Rarities, :count, :id)

if rarity_count == 0 do
  RaritiesSeeds.data()
  |> Enum.each(fn rarity ->
    Repo.insert!(%Rarities{} |> Rarities.changeset(rarity))
  end)

  IO.puts("Seeded rarities")
else
  IO.puts("Rarities already exist, skipping seeding")
end

# Check if classes exist
class_count = Repo.aggregate(Classes, :count, :id)

if class_count == 0 do
  ClassesSeeds.data()
  |> Enum.each(fn class ->
    Repo.insert!(%Classes{} |> Classes.changeset(class))
  end)

  IO.puts("Seeded weapon classes")
else
  IO.puts("Weapon classes already exist, skipping seeding")
end

# Check if effects exist
effect_count = Repo.aggregate(Effects, :count, :id)

if effect_count == 0 do
  EffectsSeeds.data()
  |> Enum.each(fn effect ->
    Repo.insert!(%Effects{} |> Effects.changeset(effect))
  end)

  IO.puts("Seeded effects")
else
  IO.puts("Effects already exist, skipping seeding")
end

# Check if enchantments exist
enchantment_count = Repo.aggregate(Enchantments, :count, :id)

if enchantment_count == 0 do
  EnchantmentsSeeds.data()
  |> Enum.each(fn enchantment ->
    Repo.insert!(%Enchantments{} |> Enchantments.changeset(enchantment))
  end)

  IO.puts("Seeded enchantments")
else
  IO.puts("Enchantments already exist, skipping seeding")
end

# Check if weapons exist
weapon_count = Repo.aggregate(Weapons, :count, :id)

if weapon_count == 0 do
  WeaponsSeeds.data()
  |> Enum.each(fn weapon ->
    Repo.insert!(%Weapons{} |> Weapons.changeset(weapon))
  end)

  IO.puts("Seeded weapons")
else
  IO.puts("Weapons already exist, skipping seeding")
end

# Check if weapon effects exist
weapon_effect_count = Repo.aggregate(WeaponEffects, :count, :id)

if weapon_effect_count == 0 do
  WeaponEffectsSeeds.data()
  |> Enum.each(fn weapon_effect ->
    Repo.insert!(%WeaponEffects{} |> WeaponEffects.changeset(weapon_effect))
  end)

  IO.puts("Seeded weapon effects")
else
  IO.puts("Weapon effects already exist, skipping seeding")
end

# Check if weapon enchantments exist
weapon_enchantment_count = Repo.aggregate(WeaponEnchantments, :count, :id)

if weapon_enchantment_count == 0 do
  WeaponEnchantmentsSeeds.data()
  |> Enum.each(fn weapon_enchantment ->
    Repo.insert!(%WeaponEnchantments{} |> WeaponEnchantments.changeset(weapon_enchantment))
  end)

  IO.puts("Seeded weapon enchantments")
else
  IO.puts("Weapon enchantments already exist, skipping seeding")
end

# Seed NPCs and Quests
alias Shard.Npcs.Npc
alias Shard.Quests.Quest

# Check if NPCs exist
npc_count = Repo.aggregate(Npc, :count, :id)

if npc_count == 0 do
  # Get the room at coordinates (1,1) for the NPC
  target_room = Repo.get_by(Room, x_coordinate: 1, y_coordinate: 1)

  if target_room do
    # Create Elder Sage Throne NPC
    _elder_sage =
      Repo.insert!(
        %Npc{}
        |> Npc.changeset(%{
          name: "Elder Sage Throne",
          description:
            "An ancient and wise sage who has watched over these lands for centuries. His eyes hold the knowledge of ages past.",
          level: 50,
          health: 500,
          max_health: 500,
          mana: 1000,
          max_mana: 1000,
          strength: 15,
          dexterity: 20,
          intelligence: 95,
          constitution: 30,
          npc_type: "quest_giver",
          dialogue:
            "Greetings, young adventurer. I have been expecting you. There are dark forces stirring in these lands that require a hero's attention.",
          location_x: 1,
          location_y: 1,
          location_z: 0,
          room_id: target_room.id,
          faction: "Order of the Light",
          aggression_level: 0,
          movement_pattern: "stationary",
          properties: %{"wisdom_level" => "ancient", "can_teach_spells" => true}
        })
      )

    IO.puts("Created Elder Sage Throne NPC")
  else
    IO.puts("Room at coordinates (1,1) not found, skipping NPC creation")
  end
else
  IO.puts("NPCs already exist, skipping NPC creation")
end

# Check if quests exist
quest_count = Repo.aggregate(Quest, :count, :id)

if quest_count == 0 do
  # Get Elder Sage Throne NPC (either just created or existing)
  elder_sage = Repo.get_by(Npc, name: "Elder Sage Throne") || Repo.get(Npc, 1)

  if elder_sage do
    # Create a starter quest for Elder Sage Throne
    Repo.insert!(
      %Quest{}
      |> Quest.changeset(%{
        title: "The Ancient Prophecy",
        description:
          "Elder Sage Throne has revealed an ancient prophecy that speaks of a great darkness approaching the realm. He believes you may be the hero foretold in the ancient texts. Your first task is to prove your worth by exploring the surrounding areas and gathering information about any strange occurrences.",
        short_description:
          "Investigate strange occurrences in the surrounding areas for Elder Sage Throne.",
        quest_type: "main",
        difficulty: "normal",
        min_level: 1,
        max_level: 10,
        experience_reward: 500,
        gold_reward: 100,
        item_rewards: %{
          "items" => [
            %{"name" => "Sage's Blessing Scroll", "quantity" => 1},
            %{"name" => "Minor Health Potion", "quantity" => 3}
          ]
        },
        prerequisites: %{},
        objectives: %{
          "primary" => [
            %{
              "description" => "Explore 3 different rooms",
              "completed" => false,
              "progress" => 0,
              "target" => 3
            },
            %{
              "description" => "Return to Elder Sage Throne",
              "completed" => false,
              "progress" => 0,
              "target" => 1
            }
          ]
        },
        status: "available",
        is_repeatable: false,
        giver_npc_id: elder_sage.id,
        turn_in_npc_id: elder_sage.id,
        location_hint: "Speak with Elder Sage Throne in the central chamber",
        faction_requirement: nil,
        faction_reward: %{
          "Order of the Light" => 50
        },
        is_active: true,
        sort_order: 1,
        properties: %{
          "is_starter_quest" => true,
          "unlocks_further_quests" => true
        }
      })
    )

    IO.puts("Created starter quest 'The Ancient Prophecy' for Elder Sage Throne")
  else
    IO.puts("Elder Sage Throne NPC not found, skipping quest creation")
  end
else
  IO.puts("Quests already exist, skipping quest creation")
end

# Spell-related seed data
alias Shard.Spells
alias Shard.Spells.{SpellTypes, SpellEffects, Spells}

# Check if spell types exist
spell_type_count = Repo.aggregate(SpellTypes, :count, :id)

if spell_type_count == 0 do
  spell_types_data = [
    %{
      name: "Holy",
      description: "Divine magic that channels the power of light and righteousness"
    },
    %{name: "Fire", description: "Destructive flames that burn enemies"},
    %{name: "Ice", description: "Freezing cold that slows and damages enemies"},
    %{name: "Shadow", description: "Dark magic that drains and corrupts"},
    %{name: "Nature", description: "Magic of the natural world, healing and protecting"},
    %{name: "Arcane", description: "Pure magical energy, raw and powerful"}
  ]

  spell_types_data
  |> Enum.each(fn spell_type ->
    Repo.insert!(%SpellTypes{} |> SpellTypes.changeset(spell_type))
  end)

  IO.puts("Seeded spell types")
else
  IO.puts("Spell types already exist, skipping seeding")
end

# Check if spell effects exist
spell_effect_count = Repo.aggregate(SpellEffects, :count, :id)

if spell_effect_count == 0 do
  spell_effects_data = [
    %{name: "Damage", description: "Deals damage to an enemy"},
    %{name: "Heal", description: "Restores health to an ally"},
    %{name: "Buff", description: "Temporarily increases stats or abilities"},
    %{name: "Debuff", description: "Temporarily decreases enemy stats or abilities"},
    %{name: "Stun", description: "Temporarily prevents the target from acting"},
    %{name: "Drain", description: "Steals health or mana from the target"}
  ]

  spell_effects_data
  |> Enum.each(fn spell_effect ->
    Repo.insert!(%SpellEffects{} |> SpellEffects.changeset(spell_effect))
  end)

  IO.puts("Seeded spell effects")
else
  IO.puts("Spell effects already exist, skipping seeding")
end

# Check if spells exist
spell_count = Repo.aggregate(Spells, :count, :id)

if spell_count == 0 do
  # Get spell types and effects for reference
  holy_type = Repo.get_by(SpellTypes, name: "Holy")
  fire_type = Repo.get_by(SpellTypes, name: "Fire")
  ice_type = Repo.get_by(SpellTypes, name: "Ice")
  nature_type = Repo.get_by(SpellTypes, name: "Nature")
  arcane_type = Repo.get_by(SpellTypes, name: "Arcane")
  shadow_type = Repo.get_by(SpellTypes, name: "Shadow")

  damage_effect = Repo.get_by(SpellEffects, name: "Damage")
  heal_effect = Repo.get_by(SpellEffects, name: "Heal")
  buff_effect = Repo.get_by(SpellEffects, name: "Buff")
  debuff_effect = Repo.get_by(SpellEffects, name: "Debuff")
  stun_effect = Repo.get_by(SpellEffects, name: "Stun")

  spells_data = [
    %{
      name: "Holy Incantation",
      description:
        "A powerful holy spell that channels divine light to smite enemies with righteous damage.",
      mana_cost: 25,
      damage: 40,
      healing: nil,
      level_required: 1,
      spell_type_id: holy_type.id,
      spell_effect_id: damage_effect.id
    },
    %{
      name: "Fireball",
      description:
        "Hurls a blazing sphere of fire at the enemy, dealing significant fire damage.",
      mana_cost: 30,
      damage: 50,
      healing: nil,
      level_required: 3,
      spell_type_id: fire_type.id,
      spell_effect_id: damage_effect.id
    },
    %{
      name: "Healing Light",
      description: "Channels holy energy to restore health to the caster or an ally.",
      mana_cost: 20,
      damage: nil,
      healing: 45,
      level_required: 1,
      spell_type_id: holy_type.id,
      spell_effect_id: heal_effect.id
    },
    %{
      name: "Ice Shard",
      description: "Launches a sharp projectile of ice that damages and may slow the target.",
      mana_cost: 20,
      damage: 35,
      healing: nil,
      level_required: 2,
      spell_type_id: ice_type.id,
      spell_effect_id: damage_effect.id
    },
    %{
      name: "Nature's Blessing",
      description: "Calls upon the forces of nature to restore health over time.",
      mana_cost: 25,
      damage: nil,
      healing: 60,
      level_required: 4,
      spell_type_id: nature_type.id,
      spell_effect_id: heal_effect.id
    },
    %{
      name: "Arcane Missiles",
      description: "Fires multiple bolts of pure arcane energy at the target.",
      mana_cost: 35,
      damage: 55,
      healing: nil,
      level_required: 5,
      spell_type_id: arcane_type.id,
      spell_effect_id: damage_effect.id
    },
    %{
      name: "Shadow Bolt",
      description: "Hurls a bolt of shadow energy that damages and may weaken the enemy.",
      mana_cost: 28,
      damage: 42,
      healing: nil,
      level_required: 3,
      spell_type_id: shadow_type.id,
      spell_effect_id: damage_effect.id
    },
    %{
      name: "Divine Shield",
      description: "Surrounds the caster with a protective holy barrier.",
      mana_cost: 40,
      damage: nil,
      healing: nil,
      level_required: 6,
      spell_type_id: holy_type.id,
      spell_effect_id: buff_effect.id
    },
    %{
      name: "Frost Nova",
      description: "Releases a burst of freezing energy that damages and stuns nearby enemies.",
      mana_cost: 45,
      damage: 38,
      healing: nil,
      level_required: 7,
      spell_type_id: ice_type.id,
      spell_effect_id: stun_effect.id
    },
    %{
      name: "Curse of Weakness",
      description: "Curses the target with shadow magic, reducing their combat effectiveness.",
      mana_cost: 30,
      damage: nil,
      healing: nil,
      level_required: 4,
      spell_type_id: shadow_type.id,
      spell_effect_id: debuff_effect.id
    }
  ]

  spells_data
  |> Enum.each(fn spell ->
    Repo.insert!(%Spells{} |> Shard.Spells.Spells.changeset(spell))
  end)

  IO.puts("Seeded spells including 'Holy Incantation'")
else
  IO.puts("Spells already exist, skipping seeding")
end

# Seed spell scroll items
alias Shard.Items.Item

# Check if spell scrolls exist
spell_scroll_count =
  Repo.one(
    from i in Item,
      where: i.item_type == "consumable" and not is_nil(i.spell_id),
      select: count(i.id)
  )

if spell_scroll_count == 0 do
  # Get some spells for the scrolls
  holy_incantation = Repo.get_by(Spells, name: "Holy Incantation")
  fireball = Repo.get_by(Spells, name: "Fireball")
  healing_light = Repo.get_by(Spells, name: "Healing Light")
  ice_shard = Repo.get_by(Spells, name: "Ice Shard")
  arcane_missiles = Repo.get_by(Spells, name: "Arcane Missiles")

  spell_scrolls = [
    %{
      name: "Scroll of Holy Incantation",
      description:
        "A sacred scroll inscribed with divine words. Reading it will teach you the Holy Incantation spell.",
      item_type: "consumable",
      rarity: "uncommon",
      value: 100,
      weight: Decimal.new("0.1"),
      stackable: false,
      usable: true,
      equippable: false,
      is_active: true,
      pickup: true,
      spell_id: holy_incantation && holy_incantation.id
    },
    %{
      name: "Scroll of Fireball",
      description:
        "An ancient scroll containing the secrets of fire magic. Reading it will teach you the Fireball spell.",
      item_type: "consumable",
      rarity: "rare",
      value: 250,
      weight: Decimal.new("0.1"),
      stackable: false,
      usable: true,
      equippable: false,
      is_active: true,
      pickup: true,
      spell_id: fireball && fireball.id
    },
    %{
      name: "Scroll of Healing Light",
      description:
        "A blessed scroll that glows with gentle radiance. Reading it will teach you the Healing Light spell.",
      item_type: "consumable",
      rarity: "uncommon",
      value: 150,
      weight: Decimal.new("0.1"),
      stackable: false,
      usable: true,
      equippable: false,
      is_active: true,
      pickup: true,
      spell_id: healing_light && healing_light.id
    },
    %{
      name: "Scroll of Ice Shard",
      description:
        "A frost-covered scroll that feels cold to the touch. Reading it will teach you the Ice Shard spell.",
      item_type: "consumable",
      rarity: "uncommon",
      value: 120,
      weight: Decimal.new("0.1"),
      stackable: false,
      usable: true,
      equippable: false,
      is_active: true,
      pickup: true,
      spell_id: ice_shard && ice_shard.id
    },
    %{
      name: "Scroll of Arcane Missiles",
      description:
        "A scroll crackling with arcane power. Reading it will teach you the Arcane Missiles spell.",
      item_type: "consumable",
      rarity: "epic",
      value: 400,
      weight: Decimal.new("0.1"),
      stackable: false,
      usable: true,
      equippable: false,
      is_active: true,
      pickup: true,
      spell_id: arcane_missiles && arcane_missiles.id
    }
  ]

  spell_scrolls
  |> Enum.each(fn scroll ->
    if scroll.spell_id do
      Repo.insert!(%Item{} |> Item.changeset(scroll))
    end
  end)

  IO.puts("Seeded spell scroll items")
else
  IO.puts("Spell scrolls already exist, skipping seeding")
end
