defmodule Shard.Weapons.WeaponTest do
  use Shard.DataCase

  alias Shard.Weapons.Weapon
  alias Shard.Weapons.Weapons
  alias Shard.Repo

  describe "get_weapon!/1" do
    test "returns a single weapon with the specified fields" do
      # First insert without foreign key constraints to avoid constraint errors
      weapon =
        %Weapons{
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
      weapon1 =
        %Weapons{
          name: "Test Sword",
          damage: 10,
          gold_value: 100,
          description: "A test sword"
        }
        |> Repo.insert!()

      weapon2 =
        %Weapons{
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
    test "returns nil when no weapon with ID 2 exists" do
      # This test verifies the current behavior of the function
      # In a real scenario, there should be a weapon with ID 2 in the database
      result = Weapon.get_tutorial_start_weapons()
      assert result == nil
    end
  end
end
