defmodule ShardWeb.AdminLive.MapFunctionsTest do
  use ShardWeb.ConnCase, async: true
  alias ShardWeb.AdminLive.MapFunctions
  alias Shard.Map

  describe "save_room/2" do
    test "creates a new room when not editing" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          editing: nil,
          changeset: nil,
          rooms: []
        }
      }

      room_params = %{
        "name" => "Test Room",
        "description" => "A test room",
        "x_coordinate" => "0",
        "y_coordinate" => "0",
        "z_coordinate" => "0",
        "room_type" => "standard",
        "is_public" => "true"
      }

      assert {:ok, updated_socket} = MapFunctions.save_room(socket, room_params)
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
      assert get_flash(updated_socket, :info) == "Room created successfully"
    end

    test "updates an existing room when editing" do
      # Create a room first
      {:ok, room} = Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      changeset = Map.change_room(room)

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          editing: :room,
          changeset: changeset,
          rooms: [room]
        }
      }

      room_params = %{
        "name" => "Updated Room",
        "description" => "An updated room",
        "x_coordinate" => "1",
        "y_coordinate" => "1",
        "z_coordinate" => "1",
        "room_type" => "safe_zone",
        "is_public" => "false"
      }

      assert {:ok, updated_socket} = MapFunctions.save_room(socket, room_params)
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
      assert get_flash(updated_socket, :info) == "Room updated successfully"
    end
  end

  describe "save_door/2" do
    setup do
      # Create two rooms for door testing
      {:ok, room1} = Map.create_room(%{
        name: "Room 1",
        description: "First room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Map.create_room(%{
        name: "Room 2",
        description: "Second room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room1: room1, room2: room2}
    end

    test "creates a new door when not editing", %{room1: room1, room2: room2} do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          editing: nil,
          changeset: nil,
          doors: []
        }
      }

      door_params = %{
        "from_room_id" => to_string(room1.id),
        "to_room_id" => to_string(room2.id),
        "direction" => "east",
        "door_type" => "standard",
        "is_locked" => "false"
      }

      assert {:ok, updated_socket} = MapFunctions.save_door(socket, door_params)
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
      assert get_flash(updated_socket, :info) == "Door created successfully"
    end

    test "updates an existing door when editing", %{room1: room1, room2: room2} do
      # Create a door first
      {:ok, door} = Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })

      changeset = Map.change_door(door)

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          editing: :door,
          changeset: changeset,
          doors: [door]
        }
      }

      door_params = %{
        "from_room_id" => to_string(room1.id),
        "to_room_id" => to_string(room2.id),
        "direction" => "west",
        "door_type" => "gate",
        "is_locked" => "true",
        "key_required" => "golden_key"
      }

      assert {:ok, updated_socket} = MapFunctions.save_door(socket, door_params)
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
      assert get_flash(updated_socket, :info) == "Door updated successfully"
    end
  end
end
