defmodule Shard.NpcsTest do
  use Shard.DataCase

  alias Shard.Npcs
  alias Shard.Npcs.Npc

  describe "npcs" do
    @valid_attrs %{
      name: "Test NPC",
      description: "A test NPC for testing",
      level: 1,
      health: 100,
      max_health: 100,
      mana: 50,
      max_mana: 50,
      npc_type: "merchant",
      room_id: 1
    }

    @invalid_attrs %{
      name: nil,
      description: nil,
      level: nil,
      health: nil,
      max_health: nil
    }

    def npc_fixture(attrs \\ %{}) do
      {:ok, npc} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Npcs.create_npc()

      npc
    end

    test "list_npcs/0 returns all npcs" do
      npc = npc_fixture()
      npcs = Npcs.list_npcs()
      assert length(npcs) >= 1
      assert Enum.any?(npcs, fn n -> n.id == npc.id end)
    end

    test "get_npc!/1 returns the npc with given id" do
      npc = npc_fixture()
      assert Npcs.get_npc!(npc.id).id == npc.id
    end

    test "get_npc!/1 raises when npc not found" do
      assert_raise Ecto.NoResultsError, fn -> Npcs.get_npc!(999) end
    end

    test "create_npc/1 with valid data creates an npc" do
      assert {:ok, %Npc{} = npc} = Npcs.create_npc(@valid_attrs)
      assert npc.name == "Test NPC"
      assert npc.description == "A test NPC for testing"
      assert npc.level == 1
      assert npc.health == 100
      assert npc.max_health == 100
      assert npc.mana == 50
      assert npc.max_mana == 50
      assert npc.npc_type == "merchant"
    end

    test "create_npc/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Npcs.create_npc(@invalid_attrs)
    end

    test "update_npc/2 with valid data updates the npc" do
      npc = npc_fixture()
      update_attrs = %{name: "Updated NPC", level: 2, health: 120}

      assert {:ok, %Npc{} = updated_npc} = Npcs.update_npc(npc, update_attrs)
      assert updated_npc.name == "Updated NPC"
      assert updated_npc.level == 2
      assert updated_npc.health == 120
    end

    test "update_npc/2 with invalid data returns error changeset" do
      npc = npc_fixture()
      assert {:error, %Ecto.Changeset{}} = Npcs.update_npc(npc, @invalid_attrs)

      refreshed_npc = Npcs.get_npc!(npc.id)
      assert refreshed_npc.name == npc.name
      assert refreshed_npc.level == npc.level
    end

    test "delete_npc/1 deletes the npc" do
      npc = npc_fixture()
      assert {:ok, %Npc{}} = Npcs.delete_npc(npc)
      assert_raise Ecto.NoResultsError, fn -> Npcs.get_npc!(npc.id) end
    end

    test "change_npc/1 returns an npc changeset" do
      npc = npc_fixture()
      assert %Ecto.Changeset{} = Npcs.change_npc(npc)
    end

    test "get_npcs_by_room/1 returns npcs in specific room" do
      room_id = 1
      npc = npc_fixture(%{room_id: room_id})
      
      npcs = Npcs.get_npcs_by_room(room_id)
      assert is_list(npcs)
      assert Enum.any?(npcs, fn n -> n.id == npc.id end)
    end

    test "get_npcs_by_location/3 returns npcs at coordinates" do
      npcs = Npcs.get_npcs_by_location(0, 0, 0)
      assert is_list(npcs)
    end

    test "get_npcs_by_type/1 returns npcs of specific type" do
      npc = npc_fixture(%{npc_type: "quest_giver"})
      
      npcs = Npcs.get_npcs_by_type("quest_giver")
      assert is_list(npcs)
      assert Enum.any?(npcs, fn n -> n.id == npc.id end)
    end

    test "get_npc_by_name/1 returns npc with given name" do
      unique_name = "Unique NPC #{System.unique_integer([:positive])}"
      npc = npc_fixture(%{name: unique_name})
      
      found_npc = Npcs.get_npc_by_name(unique_name)
      assert found_npc.id == npc.id
    end

    test "get_npc_by_name/1 returns nil for non-existent npc" do
      assert Npcs.get_npc_by_name("Non-existent NPC") == nil
    end

    test "list_rooms/0 returns list of rooms" do
      rooms = Npcs.list_rooms()
      assert is_list(rooms)
    end
  end

  describe "Npc changeset" do
    test "validates required fields" do
      changeset = Npc.changeset(%Npc{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.level
      assert "can't be blank" in errors.health
      assert "can't be blank" in errors.max_health
    end

    test "validates numeric fields are positive" do
      attrs = %{
        name: "Test NPC",
        level: -1,
        health: -1,
        max_health: -1,
        mana: -1,
        max_mana: -1
      }

      changeset = Npc.changeset(%Npc{}, attrs)
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "must be greater than 0" in errors.level
      assert "must be greater than 0" in errors.health
      assert "must be greater than 0" in errors.max_health
      assert "must be greater than or equal to 0" in errors.mana
      assert "must be greater than or equal to 0" in errors.max_mana
    end

    test "validates health does not exceed max_health" do
      attrs = %{
        name: "Test NPC",
        level: 1,
        health: 150,
        max_health: 100,
        mana: 50,
        max_mana: 50
      }

      changeset = Npc.changeset(%Npc{}, attrs)
      refute changeset.valid?
      assert %{health: ["cannot exceed max_health"]} = errors_on(changeset)
    end

    test "validates mana does not exceed max_mana" do
      attrs = %{
        name: "Test NPC",
        level: 1,
        health: 100,
        max_health: 100,
        mana: 80,
        max_mana: 50
      }

      changeset = Npc.changeset(%Npc{}, attrs)
      refute changeset.valid?
      assert %{mana: ["cannot exceed max_mana"]} = errors_on(changeset)
    end

    test "accepts valid npc data" do
      changeset = Npc.changeset(%Npc{}, @valid_attrs)
      assert changeset.valid?
    end
  end
end
