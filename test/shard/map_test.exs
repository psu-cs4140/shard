defmodule Shard.MapTest do
  use Shard.DataCase

  alias Shard.Map

  describe "rooms" do
    alias Shard.Map.Room

    import Shard.MapFixtures

    @invalid_attrs %{name: nil}

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Map.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      fetched_room = Map.get_room!(room.id)
      assert fetched_room.id == room.id
      assert fetched_room.name == room.name
    end

    test "create_room/1 with valid data creates a room" do
      valid_attrs = %{name: "Test Room", description: "A test room"}

      assert {:ok, %Room{} = room} = Map.create_room(valid_attrs)
      assert room.name == "Test Room"
      assert room.description == "A test room"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Map.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      update_attrs = %{name: "Updated Room"}

      assert {:ok, %Room{} = room} = Map.update_room(room, update_attrs)
      assert room.name == "Updated Room"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Map.update_room(room, @invalid_attrs)
      assert room == Map.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Map.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Map.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Map.change_room(room)
    end
  end

  describe "doors" do
    alias Shard.Map.Door

    import Shard.MapFixtures

    @invalid_attrs %{from_room_id: nil, to_room_id: nil, direction: nil}

    setup do
      # Create two rooms for door testing
      room1 = room_fixture(%{name: "Room 1", x_coordinate: 0, y_coordinate: 0})
      room2 = room_fixture(%{name: "Room 2", x_coordinate: 1, y_coordinate: 0})
      %{room1: room1, room2: room2}
    end

    test "list_doors/0 returns all doors" do
      door = door_fixture()
      assert Map.list_doors() == [door]
    end

    test "get_door!/1 returns the door with given id" do
      door = door_fixture()
      assert Map.get_door!(door.id) == door
    end

    test "create_door/1 with valid data creates a door and its return door", %{room1: room1, room2: room2} do
      valid_attrs = %{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "north"
      }

      assert {:ok, %Door{} = door} = Map.create_door(valid_attrs)
      assert door.direction == "north"
      assert door.from_room_id == room1.id
      assert door.to_room_id == room2.id
      
      # Check that a return door was also created
      return_door = Map.get_door_in_direction(room2.id, "south")
      assert return_door != nil
      assert return_door.direction == "south"
      assert return_door.from_room_id == room2.id
      assert return_door.to_room_id == room1.id
    end

    test "create_door/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Map.create_door(@invalid_attrs)
    end

    test "update_door/2 with valid data updates the door" do
      door = door_fixture()
      update_attrs = %{direction: "south"}

      assert {:ok, %Door{} = door} = Map.update_door(door, update_attrs)
      assert door.direction == "south"
    end

    test "update_door/2 with invalid data returns error changeset" do
      door = door_fixture()
      assert {:error, %Ecto.Changeset{}} = Map.update_door(door, @invalid_attrs)
      assert door == Map.get_door!(door.id)
    end

    test "delete_door/1 deletes the door and its return door", %{room1: room1, room2: room2} do
      valid_attrs = %{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "north"
      }
      
      assert {:ok, door} = Map.create_door(valid_attrs)
      
      # Verify the return door exists before deletion
      return_door = Map.get_door_in_direction(room2.id, "south")
      assert return_door != nil
      
      # Delete the main door
      assert {:ok, %Door{}} = Map.delete_door(door)
      assert_raise Ecto.NoResultsError, fn -> Map.get_door!(door.id) end
      
      # Verify the return door was also deleted
      assert Map.get_door_in_direction(room2.id, "south") == nil
    end

    test "change_door/1 returns a door changeset" do
      door = door_fixture()
      assert %Ecto.Changeset{} = Map.change_door(door)
    end
    
    test "create_door/1 creates return door with correct opposite directions", %{room1: room1, room2: room2} do
      direction_tests = [
        {"north", "south"},
        {"south", "north"},
        {"east", "west"},
        {"west", "east"},
        {"northeast", "southwest"},
        {"northwest", "southeast"},
        {"southeast", "northwest"},
        {"southwest", "northeast"}
      ]
      
      Enum.each(direction_tests, fn {main_direction, return_direction} ->
        # Clean up any existing doors
        Shard.Repo.delete_all(Door)
        
        valid_attrs = %{
          from_room_id: room1.id,
          to_room_id: room2.id,
          direction: main_direction
        }
        
        assert {:ok, door} = Map.create_door(valid_attrs)
        
        # Check that the return door has the correct opposite direction
        return_door = Map.get_door_in_direction(room2.id, return_direction)
        assert return_door != nil, "No return door found for direction #{main_direction} (expected #{return_direction})"
        assert return_door.direction == return_direction
        assert return_door.from_room_id == room2.id
        assert return_door.to_room_id == room1.id
      end)
    end
  end
end
