defmodule Shard.MonstersTest do
  use Shard.DataCase

  alias Shard.Monsters
  alias Shard.Monsters.Monster
  alias Shard.Repo
  alias Shard.Weapons.DamageTypes

  describe "monsters" do
    alias Shard.Monsters.Monster

    @valid_attrs %{
      attack_damage: 42,
      description: "some description",
      health: 42,
      max_health: 42,
      name: "some name",
      potential_loot_drops: %{},
      race: "some race",
      xp_amount: 42
    }
    @update_attrs %{
      attack_damage: 43,
      description: "some updated description",
      health: 43,
      max_health: 43,
      name: "some updated name",
      potential_loot_drops: %{},
      race: "some updated race",
      xp_amount: 43
    }
    @invalid_attrs %{
      attack_damage: nil,
      description: nil,
      health: nil,
      max_health: nil,
      name: nil,
      potential_loot_drops: nil,
      race: nil,
      xp_amount: nil
    }

    def monster_fixture(attrs \\ %{}) do
      {:ok, monster} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Monsters.create_monster()

      monster
    end

    test "list_monsters/0 returns all monsters" do
      # Create a test monster and verify it's in the list
      test_monster = monster_fixture()

      # Get all monsters and find our test monster
      all_monsters = Monsters.list_monsters()
      found_monster = Enum.find(all_monsters, fn m -> m.id == test_monster.id end)

      # Verify our test monster is in the list
      assert found_monster != nil
      assert found_monster.id == test_monster.id
      assert found_monster.name == test_monster.name
    end

    test "get_monster!/1 returns the monster with given id" do
      monster = monster_fixture()
      retrieved_monster = Monsters.get_monster!(monster.id)

      # Compare specific fields instead of entire structs to avoid association loading issues
      assert retrieved_monster.id == monster.id
      assert retrieved_monster.name == monster.name
      assert retrieved_monster.attack_damage == monster.attack_damage
      assert retrieved_monster.description == monster.description
      assert retrieved_monster.health == monster.health
      assert retrieved_monster.max_health == monster.max_health
      assert retrieved_monster.race == monster.race
      assert retrieved_monster.xp_amount == monster.xp_amount
    end

    test "create_monster/1 with valid data creates a monster" do
      assert {:ok, %Monster{} = monster} = Monsters.create_monster(@valid_attrs)
      assert monster.attack_damage == 42
      assert monster.description == "some description"
      assert monster.health == 42
      assert monster.max_health == 42
      assert monster.name == "some name"
      assert monster.potential_loot_drops == %{}
      assert monster.race == "some race"
      assert monster.xp_amount == 42
    end

    test "create_monster/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monsters.create_monster(@invalid_attrs)
    end

    test "update_monster/2 with valid data updates the monster" do
      monster = monster_fixture()
      assert {:ok, %Monster{} = monster} = Monsters.update_monster(monster, @update_attrs)
      assert monster.attack_damage == 43
      assert monster.description == "some updated description"
      assert monster.health == 43
      assert monster.max_health == 43
      assert monster.name == "some updated name"
      assert monster.potential_loot_drops == %{}
      assert monster.race == "some updated race"
      assert monster.xp_amount == 43
    end

    test "update_monster/2 with invalid data returns error changeset" do
      monster = monster_fixture()
      assert {:error, %Ecto.Changeset{}} = Monsters.update_monster(monster, @invalid_attrs)

      # Retrieve the monster again and verify it hasn't changed
      unchanged_monster = Monsters.get_monster!(monster.id)
      assert unchanged_monster.id == monster.id
      assert unchanged_monster.name == monster.name
      assert unchanged_monster.attack_damage == monster.attack_damage
    end

    test "delete_monster/1 deletes the monster" do
      monster = monster_fixture()
      assert {:ok, %Monster{}} = Monsters.delete_monster(monster)
      assert_raise Ecto.NoResultsError, fn -> Monsters.get_monster!(monster.id) end
    end

    test "change_monster/1 returns a monster changeset" do
      monster = monster_fixture()
      assert %Ecto.Changeset{} = Monsters.change_monster(monster)
    end
  end

  describe "special damage monsters" do
    setup do
      # Create a poison damage type for testing
      {:ok, poison_type} =
        %DamageTypes{}
        |> DamageTypes.changeset(%{name: "Poison"})
        |> Repo.insert()

      %{
        poison_type: poison_type
      }
    end

    test "create monster with special damage attributes", %{poison_type: poison_type} do
      attrs =
        Map.merge(@valid_attrs, %{
          special_damage_type_id: poison_type.id,
          special_damage_amount: 2,
          special_damage_duration: 3,
          special_damage_chance: 50
        })

      assert {:ok, %Monster{} = monster} = Monsters.create_monster(attrs)
      assert monster.special_damage_type_id == poison_type.id
      assert monster.special_damage_amount == 2
      assert monster.special_damage_duration == 3
      assert monster.special_damage_chance == 50
    end

    test "validates special damage amount is non-negative" do
      attrs =
        Map.merge(@valid_attrs, %{
          special_damage_amount: -1
        })

      assert {:error, %Ecto.Changeset{} = changeset} = Monsters.create_monster(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).special_damage_amount
    end

    test "validates special damage duration is non-negative" do
      attrs =
        Map.merge(@valid_attrs, %{
          special_damage_duration: -1
        })

      assert {:error, %Ecto.Changeset{} = changeset} = Monsters.create_monster(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).special_damage_duration
    end

    test "validates special damage chance is between 0 and 100" do
      attrs =
        Map.merge(@valid_attrs, %{
          special_damage_chance: -1
        })

      assert {:error, %Ecto.Changeset{} = changeset} = Monsters.create_monster(attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).special_damage_chance

      attrs =
        Map.merge(@valid_attrs, %{
          special_damage_chance: 101
        })

      assert {:error, %Ecto.Changeset{} = changeset} = Monsters.create_monster(attrs)
      assert "must be less than or equal to 100" in errors_on(changeset).special_damage_chance
    end

    test "special damage type can be nil" do
      attrs =
        Map.merge(@valid_attrs, %{
          special_damage_type_id: nil,
          special_damage_amount: 0,
          special_damage_duration: 0,
          special_damage_chance: 100
        })

      assert {:ok, %Monster{} = monster} = Monsters.create_monster(attrs)
      assert monster.special_damage_type_id == nil
    end
  end
end
