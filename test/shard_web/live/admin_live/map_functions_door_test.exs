defmodule ShardWeb.AdminLive.MapFunctionsDoorTest do
  use ShardWeb.ConnCase, async: true
  alias ShardWeb.AdminLive.MapFunctions
  alias Phoenix.LiveView.Socket

  # Helper function to create a socket with required assigns
  defp create_socket(assigns) do
    default_assigns = %{
      rooms: [],
      doors: [],
      editing: nil,
      changeset: nil,
      flash: %{},
      __changed__: %{},
      selected_zone_id: nil
    }

    merged_assigns = :maps.merge(default_assigns, assigns)

    # Create socket with proper assigns
    %Socket{
      assigns: merged_assigns
    }
  end

  describe "save_door/2" do
    test "creates a new door when not editing" do
      # Create rooms for the door
      {:ok, room1} =
        Shard.Map.create_room(%{
          name: "Room 1",
          description: "First room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      {:ok, room2} =
        Shard.Map.create_room(%{
          name: "Room 2",
          description: "Second room",
          x_coordinate: 1,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      socket =
        create_socket(%{
          editing: nil,
          changeset: nil,
          rooms: [room1, room2],
          doors: []
        })

      # Use string IDs to match form submission format (like the UI sends)
      door_params = %{
        "from_room_id" => "#{room1.id}",
        "to_room_id" => "#{room2.id}",
        "direction" => "east",
        "door_type" => "standard",
        "is_locked" => "false"
      }

      assert {:ok, updated_socket} = MapFunctions.save_door(socket, door_params)
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Door created successfully"
      # At least one door should be created
      assert length(updated_socket.assigns.doors) >= 1
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end

    test "updates an existing door when editing" do
      # Create rooms for the door
      {:ok, room1} =
        Shard.Map.create_room(%{
          name: "Room 1",
          description: "First room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      {:ok, room2} =
        Shard.Map.create_room(%{
          name: "Room 2",
          description: "Second room",
          x_coordinate: 1,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      # Create a door for editing
      {:ok, door} =
        Shard.Map.create_door(%{
          from_room_id: room1.id,
          to_room_id: room2.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })

      changeset = Shard.Map.change_door(door)

      socket =
        create_socket(%{
          editing: :door,
          changeset: changeset,
          rooms: [room1, room2],
          doors: [door]
        })

      # Use string IDs to match form submission format (like the UI sends)
      door_params = %{
        "id" => "#{door.id}",
        "from_room_id" => "#{room1.id}",
        "to_room_id" => "#{room2.id}",
        # Changed direction to avoid constraint issues
        "direction" => "west",
        "door_type" => "standard",
        "is_locked" => "true"
      }

      assert {:ok, updated_socket} = MapFunctions.save_door(socket, door_params)
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Door updated successfully"
      # Find the specific door we updated by ID
      updated_door = Enum.find(updated_socket.assigns.doors, &(&1.id == door.id))
      assert updated_door != nil
      assert updated_door.direction == "west"
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end
end
