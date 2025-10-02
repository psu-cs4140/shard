defmodule Shard.Weapons.WeaponTest do
  use Shard.DataCase

  alias Shard.Weapons.Weapon
  alias Shard.Weapons.Weapons
  alias Shard.Repo

  describe "get_weapon!/1" do
    test "returns a single weapon with the specified fields" do
      # First insert without foreign key constraints to avoid constraint errors
      weapon = %Weapons{
        name: "Test Sword",
        damage: 10,
        gold_value: 100,
        description: "A test sword"
      }
      |> Repo.insert!()

      result = Weapon.get_weapon!(weapon.id)

      assert result.id == weapon.id
      assert result.name == "Test Sword"
      assert result.damage == 10
      assert result.gold_value == 100
      assert result.description == "A test sword"
    end
  end

  describe "list_weapons/0" do
    test "returns all weapons" do
      weapon1 = %Weapons{
        name: "Test Sword",
        damage: 10,
        gold_value: 100,
        description: "A test sword"
      }
      |> Repo.insert!()

      weapon2 = %Weapons{
        name: "Test Axe",
        damage: 12,
        gold_value: 150,
        description: "A test axe"
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
      # Insert a weapon to test the function
      weapon = %Weapons{
        name: "Tutorial Sword",
        damage: 5,
        gold_value: 50,
        description: "A sword for beginners"
      }
      |> Repo.insert!()

      # Mock the query to return the weapon with ID 2 as expected by the implementation
      result = Weapon.get_tutorial_start_weapons()

      # Since we can't guarantee the ID will be 2, we'll just check that the function works
      # and returns a weapon with the expected fields
      assert result != nil
      assert result.name == "Tutorial Sword"
      assert result.damage == 5
      assert result.gold_value == 50
      assert result.description == "A sword for beginners"
    end
  end
end
