defmodule ShardWeb.AdminLive.MapHandlersDoorTest do
  use ShardWeb.ConnCase, async: true
  alias ShardWeb.AdminLive.MapHandlers
  alias Phoenix.LiveView.Socket

  # Helper function to create a socket with required assigns
  defp create_socket(assigns) do
    default_assigns = %{
      tab: "rooms",
      rooms: [],
      doors: [],
      editing: nil,
      changeset: nil,
      viewing: nil,
      zoom: 1.0,
      pan_x: 0,
      pan_y: 0,
      drag_start: nil,
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

  describe "handle_new_door/2" do
    test "sets up a new door form" do
      socket = create_socket(%{editing: nil, changeset: nil})

      {:noreply, updated_socket} = MapHandlers.handle_new_door(%{}, socket)

      assert updated_socket.assigns.editing == :door
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == nil
      assert updated_socket.assigns.changeset.data.__struct__ == Shard.Map.Door
    end
  end

  describe "handle_edit_door/2" do
    test "sets up an existing door for editing" do
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

      socket = create_socket(%{editing: nil, changeset: nil})

      params = %{"id" => "#{door.id}"}
      {:noreply, updated_socket} = MapHandlers.handle_edit_door(params, socket)

      assert updated_socket.assigns.editing == :door
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.data.id == door.id
    end
  end

  describe "handle_delete_door/2" do
    test "deletes a door successfully" do
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

      # Create a door to delete - use unique direction
      {:ok, _door} =
        Shard.Map.create_door(%{
          from_room_id: room1.id,
          to_room_id: room2.id,
          direction: "north",
          door_type: "standard",
          is_locked: false
        })

      # Refresh the doors list to include both the created door and its automatic return door
      all_doors = Shard.Map.list_doors()
      created_door = Enum.find(all_doors, &(&1.direction == "north"))
      initial_door_count = length(all_doors)

      socket = create_socket(%{rooms: [room1, room2], doors: all_doors})

      params = %{"id" => "#{created_door.id}"}
      {:noreply, updated_socket} = MapHandlers.handle_delete_door(params, socket)

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Door deleted successfully"
      # Check that the specific door was deleted
      assert not Enum.any?(updated_socket.assigns.doors, &(&1.id == created_door.id))
      # Check that the door count decreased (should be fewer doors than before)
      assert length(updated_socket.assigns.doors) < initial_door_count
    end
  end

  describe "handle_save_door/2" do
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

      # Convert IDs to appropriate string types to match form submission
      door_params = %{
        "from_room_id" => "#{room1.id}",
        "to_room_id" => "#{room2.id}",
        "direction" => "east",
        "door_type" => "standard",
        "is_locked" => "false"
      }

      params = %{"door" => door_params}
      {:noreply, updated_socket} = MapHandlers.handle_save_door(params, socket)

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Door created successfully"
      # Should have at least 1 door (created door + automatic return door)
      assert updated_socket.assigns.doors != []
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
      {:ok, _door} =
        Shard.Map.create_door(%{
          from_room_id: room1.id,
          to_room_id: room2.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })

      # Get all doors including the automatically created return door
      all_doors = Shard.Map.list_doors()
      main_door = Enum.find(all_doors, &(&1.direction == "east"))

      changeset = Shard.Map.change_door(main_door)

      socket =
        create_socket(%{
          editing: :door,
          changeset: changeset,
          rooms: [room1, room2],
          doors: all_doors
        })

      # Use appropriate string types to match form submission
      door_params = %{
        "id" => "#{main_door.id}",
        "from_room_id" => "#{room1.id}",
        "to_room_id" => "#{room2.id}",
        # Changed direction to avoid constraint issues
        "direction" => "west",
        "door_type" => "standard",
        "is_locked" => "true"
      }

      params = %{"door" => door_params}
      {:noreply, updated_socket} = MapHandlers.handle_save_door(params, socket)

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Door updated successfully"
      # Use a more direct way to check the direction
      updated_door = Enum.find(updated_socket.assigns.doors, &(&1.id == main_door.id))
      assert updated_door.direction == "west"
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end

  describe "handle_validate_door/2" do
    test "validates door changeset when creating new door" do
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
          rooms: [room1, room2]
        })

      # Use appropriate string types to match form submission
      door_params = %{
        "from_room_id" => "#{room1.id}",
        "to_room_id" => "#{room2.id}",
        "direction" => "",
        "door_type" => "standard",
        "is_locked" => "false"
      }

      {:noreply, updated_socket} =
        MapHandlers.handle_validate_door(%{"door" => door_params}, socket)

      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == :validate
      assert updated_socket.assigns.changeset.errors != []
    end

    test "validates door changeset when editing existing door" do
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
      {:ok, _door} =
        Shard.Map.create_door(%{
          from_room_id: room1.id,
          to_room_id: room2.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })

      # Get the main door (not the return door) for editing
      all_doors = Shard.Map.list_doors()
      main_door = Enum.find(all_doors, &(&1.direction == "east"))

      changeset = Shard.Map.change_door(main_door)

      socket =
        create_socket(%{
          editing: :door,
          changeset: changeset,
          rooms: [room1, room2]
        })

      # Use appropriate string types to match form submission
      door_params = %{
        "id" => "#{main_door.id}",
        "from_room_id" => "#{room1.id}",
        "to_room_id" => "#{room2.id}",
        "direction" => "",
        "door_type" => "standard",
        "is_locked" => "true"
      }

      {:noreply, updated_socket} =
        MapHandlers.handle_validate_door(%{"door" => door_params}, socket)

      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == :validate
      assert updated_socket.assigns.changeset.data.id == main_door.id
      assert updated_socket.assigns.changeset.errors != []
    end
  end

  describe "handle_cancel_door/2" do
    test "cancels door editing and clears changeset" do
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
      {:ok, _door} =
        Shard.Map.create_door(%{
          from_room_id: room1.id,
          to_room_id: room2.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })

      # Get the main door for editing
      all_doors = Shard.Map.list_doors()
      main_door = Enum.find(all_doors, &(&1.direction == "east"))

      changeset = Shard.Map.change_door(main_door)

      socket =
        create_socket(%{
          editing: :door,
          changeset: changeset
        })

      {:noreply, updated_socket} = MapHandlers.handle_cancel_door(%{}, socket)

      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end
end
