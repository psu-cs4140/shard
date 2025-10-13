defmodule Shard.MonstersTest do
  use Shard.DataCase

  alias Shard.Monsters
  alias Shard.Monsters.Monster
  alias Shard.Map.Room
  alias Shard.Repo

  describe "monsters" do
    @valid_attrs %{
      name: "Goblin",
      race: "Goblinoid",
      health: 25,
      max_health: 25,
      attack_damage: 5,
      potential_loot_drops: %{"gold" => 10, "dagger" => 0.1},
      xp_amount: 50,
      level: 1,
      description: "A small, green creature with sharp teeth."
    }

    @update_attrs %{
      name: "Orc",
      race: "Orcish",
      health: 50,
      max_health: 50,
      attack_damage: 10,
      potential_loot_drops: %{"gold" => 20, "sword" => 0.05},
      xp_amount: 100,
      level: 2,
      description: "A large, brutish creature with tusks."
    }

    @invalid_attrs %{
      name: nil,
      race: nil,
      health: nil,
      max_health: nil,
      attack_damage: nil,
      xp_amount: nil
    }

    def room_fixture(attrs \\ %{}) do
      {:ok, room} =
        attrs
        |> Enum.into(%{
          name: "Test Room",
          description: "A test room for monsters"
        })
        |> then(&%Room{} |> Room.changeset(&1) |> Repo.insert())

      room
    end

    def monster_fixture(attrs \\ %{}) do
      {:ok, monster} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Monsters.create_monster()

      monster
    end

    test "list_monsters/0 returns all monsters" do
      monster = monster_fixture()
      assert Monsters.list_monsters() == [monster]
    end

    test "get_monster!/1 returns the monster with given id" do
      monster = monster_fixture()
      assert Monsters.get_monster!(monster.id) == monster
    end

    test "get_monster!/1 raises when monster does not exist" do
      assert_raise Ecto.NoResultsError, fn -> Monsters.get_monster!(999) end
    end

    test "get_monsters_by_location/1 returns monsters in the given location" do
      room1 = room_fixture()
      room2 = room_fixture()
      
      monster1 = monster_fixture(%{location_id: room1.id})
      monster2 = monster_fixture(%{location_id: room1.id})
      _monster3 = monster_fixture(%{location_id: room2.id})

      monsters = Monsters.get_monsters_by_location(room1.id)
      assert length(monsters) == 2
      assert Enum.member?(monsters, monster1)
      assert Enum.member?(monsters, monster2)
    end

    test "get_monsters_by_location/1 returns empty list when no monsters in location" do
      assert Monsters.get_monsters_by_location(999) == []
    end

    test "create_monster/1 with valid data creates a monster" do
      assert {:ok, %Monster{} = monster} = Monsters.create_monster(@valid_attrs)
      assert monster.name == "Goblin"
      assert monster.race == "Goblinoid"
      assert monster.health == 25
      assert monster.max_health == 25
      assert monster.attack_damage == 5
      assert monster.potential_loot_drops == %{"gold" => 10, "dagger" => 0.1}
      assert monster.xp_amount == 50
      assert monster.level == 1
      assert monster.description == "A small, green creature with sharp teeth."
    end

    test "create_monster/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Monsters.create_monster(@invalid_attrs)
    end

    test "update_monster/2 with valid data updates the monster" do
      monster = monster_fixture()
      assert {:ok, %Monster{} = monster} = Monsters.update_monster(monster, @update_attrs)
      assert monster.name == "Orc"
      assert monster.race == "Orcish"
      assert monster.health == 50
      assert monster.max_health == 50
      assert monster.attack_damage == 10
      assert monster.potential_loot_drops == %{"gold" => 20, "sword" => 0.05}
      assert monster.xp_amount == 100
      assert monster.level == 2
      assert monster.description == "A large, brutish creature with tusks."
    end

    test "update_monster/2 with invalid data returns error changeset" do
      monster = monster_fixture()
      assert {:error, %Ecto.Changeset{}} = Monsters.update_monster(monster, @invalid_attrs)
      assert monster == Monsters.get_monster!(monster.id)
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

  describe "monster schema validations" do
    test "changeset with valid attributes" do
      changeset = Monster.changeset(%Monster{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires name" do
      attrs = Map.delete(@valid_attrs, :name)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "changeset requires race" do
      attrs = Map.delete(@valid_attrs, :race)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "can't be blank" in errors_on(changeset).race
    end

    test "changeset requires health" do
      attrs = Map.delete(@valid_attrs, :health)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "can't be blank" in errors_on(changeset).health
    end

    test "changeset requires max_health" do
      attrs = Map.delete(@valid_attrs, :max_health)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "can't be blank" in errors_on(changeset).max_health
    end

    test "changeset requires attack_damage" do
      attrs = Map.delete(@valid_attrs, :attack_damage)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "can't be blank" in errors_on(changeset).attack_damage
    end

    test "changeset requires xp_amount" do
      attrs = Map.delete(@valid_attrs, :xp_amount)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "can't be blank" in errors_on(changeset).xp_amount
    end

    test "changeset validates health is greater than 0" do
      attrs = Map.put(@valid_attrs, :health, 0)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "must be greater than 0" in errors_on(changeset).health
    end

    test "changeset validates max_health is greater than 0" do
      attrs = Map.put(@valid_attrs, :max_health, 0)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "must be greater than 0" in errors_on(changeset).max_health
    end

    test "changeset validates attack_damage is greater than or equal to 0" do
      attrs = Map.put(@valid_attrs, :attack_damage, -1)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).attack_damage
    end

    test "changeset allows attack_damage to be 0" do
      attrs = Map.put(@valid_attrs, :attack_damage, 0)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert changeset.valid?
    end

    test "changeset validates xp_amount is greater than or equal to 0" do
      attrs = Map.put(@valid_attrs, :xp_amount, -1)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "must be greater than or equal to 0" in errors_on(changeset).xp_amount
    end

    test "changeset allows xp_amount to be 0" do
      attrs = Map.put(@valid_attrs, :xp_amount, 0)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert changeset.valid?
    end

    test "changeset validates level is greater than 0" do
      attrs = Map.put(@valid_attrs, :level, 0)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "must be greater than 0" in errors_on(changeset).level
    end

    test "changeset validates health does not exceed max_health" do
      attrs = Map.merge(@valid_attrs, %{health: 30, max_health: 25})
      changeset = Monster.changeset(%Monster{}, attrs)
      assert "cannot exceed max health" in errors_on(changeset).health
    end

    test "changeset allows health to equal max_health" do
      attrs = Map.merge(@valid_attrs, %{health: 25, max_health: 25})
      changeset = Monster.changeset(%Monster{}, attrs)
      assert changeset.valid?
    end

    test "changeset allows health to be less than max_health" do
      attrs = Map.merge(@valid_attrs, %{health: 20, max_health: 25})
      changeset = Monster.changeset(%Monster{}, attrs)
      assert changeset.valid?
    end

    test "changeset sets default level to 1" do
      attrs = Map.delete(@valid_attrs, :level)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert get_field(changeset, :level) == 1
    end

    test "changeset sets default potential_loot_drops to empty map" do
      attrs = Map.delete(@valid_attrs, :potential_loot_drops)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert get_field(changeset, :potential_loot_drops) == %{}
    end

    test "changeset accepts map for potential_loot_drops" do
      loot_drops = %{"gold" => 15, "potion" => 0.2, "armor" => 0.05}
      attrs = Map.put(@valid_attrs, :potential_loot_drops, loot_drops)
      changeset = Monster.changeset(%Monster{}, attrs)
      assert changeset.valid?
      assert get_field(changeset, :potential_loot_drops) == loot_drops
    end
  end
end
