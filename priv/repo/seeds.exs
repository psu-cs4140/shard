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
    Repo.insert!(%Door{} |> Door.changeset(%{
      from_room_id: from_room.id,
      to_room_id: to_room.id,
      direction: "east",
      door_type: "standard",
      is_locked: false,
      properties: %{"state" => "open"}
    }))
    
    # Door from right room to left room (west)
    Repo.insert!(%Door{} |> Door.changeset(%{
      from_room_id: to_room.id,
      to_room_id: from_room.id,
      direction: "west",
      door_type: "standard",
      is_locked: false,
      properties: %{"state" => "open"}
    }))
  end

  # Connect vertically (north-south)
  for x <- 0..2, y <- 0..1 do
    from_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
    to_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y + 1))
    
    # Door from bottom room to top room (north)
    Repo.insert!(%Door{} |> Door.changeset(%{
      from_room_id: from_room.id,
      to_room_id: to_room.id,
      direction: "north",
      door_type: "standard",
      is_locked: false,
      properties: %{"state" => "open"}
    }))
    
    # Door from top room to bottom room (south)
    Repo.insert!(%Door{} |> Door.changeset(%{
      from_room_id: to_room.id,
      to_room_id: from_room.id,
      direction: "south",
      door_type: "standard",
      is_locked: false,
      properties: %{"state" => "open"}
    }))
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
