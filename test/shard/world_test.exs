defmodule Shard.WorldTest do
  use Shard.DataCase
  @valid_attrs %{name: "some name", slug: "some-slug", species: "some species", description: "some description",
                level: 42, hp: 42, attack: 42, defense: 42, speed: 42, xp_drop: 42,
                element: "fire", ai: "aggressive", spawn_rate: 42}

  @update_attrs %{name: "some updated name", slug: "some-updated-slug", species: "some updated species", description: "some updated description",
                 level: 43, hp: 43, attack: 43, defense: 43, speed: 43, xp_drop: 43,
                 element: "fire", ai: "aggressive", spawn_rate: 43}

  @invalid_attrs %{name: nil, slug: nil, species: nil, description: nil, level: nil, hp: nil, attack: nil, defense: nil, speed: nil, xp_drop: nil, element: nil, ai: nil, spawn_rate: nil}

  alias Shard.World

  describe "monsters" do
    alias Shard.World.Monster

    import Shard.WorldFixtures


    test "list_monsters/0 returns all monsters" do
      monster = monster_fixture()
      assert World.list_monsters() == [monster]
    end

    test "get_monster!/1 returns the monster with given id" do
      monster = monster_fixture()
      assert World.get_monster!(monster.id) == monster
    end

    test "create_monster/1 with valid data creates a monster" do
      valid_attrs = %{name: "some name", element: "fire", level: 42, description: "some description", speed: 42, slug: "some slug", species: "some species", hp: 42, attack: 42, defense: 42, xp_drop: 42, ai: "aggressive", spawn_rate: 42}

      assert {:ok, %Monster{} = monster} = World.create_monster(valid_attrs)
      assert monster.name == "some name"
      assert to_string(monster.element) == @valid_attrs[:element]
      assert monster.level == 42
      assert monster.description == "some description"
      assert monster.speed == 42
      assert monster.slug == "some slug"
      assert monster.species == "some species"
      assert monster.hp == 42
      assert monster.attack == 42
      assert monster.defense == 42
      assert monster.xp_drop == 42
      assert to_string(monster.ai) == @valid_attrs[:ai]
      assert monster.spawn_rate == 42
    end

    test "create_monster/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = World.create_monster(@invalid_attrs)
    end

    test "update_monster/2 with valid data updates the monster" do
      monster = monster_fixture()
      update_attrs = %{name: "some updated name", element: "fire", level: 43, description: "some updated description", speed: 43, slug: "some updated slug", species: "some updated species", hp: 43, attack: 43, defense: 43, xp_drop: 43, ai: "aggressive", spawn_rate: 43}

      assert {:ok, %Monster{} = monster} = World.update_monster(monster, update_attrs)
      assert monster.name == "some updated name"
      assert to_string(monster.element) == @update_attrs[:element]
      assert monster.level == 43
      assert monster.description == "some updated description"
      assert monster.speed == 43
      assert monster.slug == "some updated slug"
      assert monster.species == "some updated species"
      assert monster.hp == 43
      assert monster.attack == 43
      assert monster.defense == 43
      assert monster.xp_drop == 43
      assert to_string(monster.ai) == @update_attrs[:ai]
      assert monster.spawn_rate == 43
    end

    test "update_monster/2 with invalid data returns error changeset" do
      monster = monster_fixture()
      assert {:error, %Ecto.Changeset{}} = World.update_monster(monster, @invalid_attrs)
      assert monster == World.get_monster!(monster.id)
    end

    test "delete_monster/1 deletes the monster" do
      monster = monster_fixture()
      assert {:ok, %Monster{}} = World.delete_monster(monster)
      assert_raise Ecto.NoResultsError, fn -> World.get_monster!(monster.id) end
    end

    test "change_monster/1 returns a monster changeset" do
      monster = monster_fixture()
      assert %Ecto.Changeset{} = World.change_monster(monster)
    end
  end
end
