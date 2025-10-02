defmodule Shard.Weapons.WeaponTest do
  use Shard.DataCase

  alias Shard.Weapons.Weapon
  alias Shard.Weapons.Weapons
  alias Shard.Repo

  describe "get_weapon!/1" do
    test "returns a single weapon with the specified fields" do
      weapon = %Weapons{
        name: "Test Sword",
        damage: 10,
        gold_value: 100,
        description: "A test sword",
        weapon_class_id: 1,
        rarity_id: 1
      }
      |> Repo.insert!()

      result = Weapon.get_weapon!(weapon.id)

      assert result.id == weapon.id
      assert result.name == "Test Sword"
      assert result.damage == 10
      assert result.gold_value == 100
      assert result.description == "A test sword"
      assert result.weapon_class_id == 1
      assert result.rarity_id == 1
    end
  end

  describe "list_weapons/0" do
    test "returns all weapons" do
      weapon1 = %Weapons{
        name: "Test Sword",
        damage: 10,
        gold_value: 100,
        description: "A test sword",
        weapon_class_id: 1,
        rarity_id: 1
      }
      |> Repo.insert!()

      weapon2 = %Weapons{
        name: "Test Axe",
        damage: 12,
        gold_value: 150,
        description: "A test axe",
        weapon_class_id: 2,
        rarity_id: 1
      }
      |> Repo.insert!()

      weapons = Weapon.list_weapons()

      assert length(weapons) >= 2
      assert weapon1.id in Enum.map(weapons, & &1.id)
      assert weapon2.id in Enum.map(weapons, & &1.id)
    end
  end

  describe "get_tutorial_start_weapons/0" do
    test "returns the tutorial start weapon with the specified fields" do
      # Insert a weapon with ID 2 to match the implementation
      weapon = %Weapons{
        id: 2,
        name: "Tutorial Sword",
        damage: 5,
        gold_value: 50,
        description: "A sword for beginners",
        weapon_class_id: 1,
        rarity_id: 1
      }
      |> Repo.insert!()

      result = Weapon.get_tutorial_start_weapons()

      assert result.id == weapon.id
      assert result.name == "Tutorial Sword"
      assert result.damage == 5
      assert result.gold_value == 50
      assert result.description == "A sword for beginners"
      assert result.weapon_class_id == 1
      assert result.rarity_id == 1
    end
  end
end
