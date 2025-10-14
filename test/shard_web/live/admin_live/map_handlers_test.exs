defmodule ShardWeb.AdminLive.MapHandlersTest do
  use ShardWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias ShardWeb.AdminLive.MapHandlers
  alias Phoenix.LiveView.Socket

  # Helper function to create a socket with required assigns
  defp create_socket(assigns \\ %{}) do
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
      flash: %{}
    }

    %Socket{
      assigns: Map.merge(default_assigns, assigns)
    }
  end

  describe "handle_change_tab/2" do
    test "changes the tab correctly" do
      socket = create_socket(%{tab: "rooms"})
      params = %{"tab" => "doors"}

      {:noreply, updated_socket} = MapHandlers.handle_change_tab(params, socket)

      assert updated_socket.assigns.tab == "doors"
    end
  end

  describe "handle_new_room/2" do
    test "sets up a new room form" do
      socket = create_socket(%{editing: nil, changeset: nil})

      {:noreply, updated_socket} = MapHandlers.handle_new_room(%{}, socket)

      assert updated_socket.assigns.editing == :room
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == nil
      assert updated_socket.assigns.changeset.data.__struct__ == Shard.Map.Room
    end
  end

  describe "handle_edit_room/2" do
    test "sets up an existing room for editing" do
      # Create a room for editing
      {:ok, room} = Shard.Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      socket = create_socket(%{editing: nil, changeset: nil})

      params = %{"id" => to_string(room.id)}
      {:noreply, updated_socket} = MapHandlers.handle_edit_room(params, socket)
      
      assert updated_socket.assigns.editing == :room
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.data.id == room.id
    end
  end

  describe "handle_delete_room/2" do
    test "deletes a room successfully" do
      # Create a room to delete
      {:ok, room} = Shard.Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      # Create another room to ensure list functionality
      {:ok, room2} = Shard.Map.create_room(%{
        name: "Test Room 2",
        description: "Another test room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      socket = create_socket(%{rooms: [room, room2], doors: []})

      params = %{"id" => to_string(room.id)}
      {:noreply, updated_socket} = MapHandlers.handle_delete_room(params, socket)
      
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Room deleted successfully"
      assert length(updated_socket.assigns.rooms) == 1
      assert List.first(updated_socket.assigns.rooms).id == room2.id
    end
  end

  describe "handle_view_room/2" do
    test "sets up room details view" do
      # Create a room to view
      {:ok, room} = Shard.Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      socket = create_socket(%{tab: "rooms"})

      params = %{"id" => to_string(room.id)}
      {:noreply, updated_socket} = MapHandlers.handle_view_room(params, socket)
      
      assert updated_socket.assigns.tab == "room_details"
      assert updated_socket.assigns.viewing.id == room.id
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.data.id == room.id
    end
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
      {:ok, room1} = Shard.Map.create_room(%{
        name: "Room 1",
        description: "First room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Shard.Map.create_room(%{
        name: "Room 2",
        description: "Second room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      # Create a door for editing
      {:ok, door} = Shard.Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })

      socket = create_socket(%{editing: nil, changeset: nil})

      params = %{"id" => to_string(door.id)}
      {:noreply, updated_socket} = MapHandlers.handle_edit_door(params, socket)
      
      assert updated_socket.assigns.editing == :door
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.data.id == door.id
    end
  end

  describe "handle_delete_door/2" do
    test "deletes a door successfully" do
      # Create rooms for the door
      {:ok, room1} = Shard.Map.create_room(%{
        name: "Room 1",
        description: "First room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Shard.Map.create_room(%{
        name: "Room 2",
        description: "Second room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      # Create a door to delete
      {:ok, door} = Shard.Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })

      # Create another door to ensure list functionality
      {:ok, door2} = Shard.Map.create_door(%{
        from_room_id: room2.id,
        to_room_id: room1.id,
        direction: "west",
        door_type: "standard",
        is_locked: false
      })

      socket = create_socket(%{rooms: [room1, room2], doors: [door, door2]})

      params = %{"id" => to_string(door.id)}
      {:noreply, updated_socket} = MapHandlers.handle_delete_door(params, socket)
      
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Door deleted successfully"
      assert length(updated_socket.assigns.doors) == 1
      assert List.first(updated_socket.assigns.doors).id == door2.id
    end
  end

  describe "handle_validate_room/2" do
    test "validates room changeset when creating new room" do
      socket = create_socket(%{
        editing: nil,
        changeset: nil
      })

      room_params = %{
        "name" => "",
        "description" => "A test room",
        "x_coordinate" => "0",
        "y_coordinate" => "0",
        "z_coordinate" => "0",
        "room_type" => "standard",
        "is_public" => "true"
      }

      {:noreply, updated_socket} = MapHandlers.handle_validate_room(%{"room" => room_params}, socket)
      
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == :validate
      assert updated_socket.assigns.changeset.errors != []
    end

    test "validates room changeset when editing existing room" do
      # Create a room for editing
      {:ok, room} = Shard.Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      changeset = Shard.Map.change_room(room)
      socket = create_socket(%{
        editing: :room,
        changeset: changeset
      })

      room_params = %{
        "name" => "",
        "description" => "Updated description",
        "x_coordinate" => "0",
        "y_coordinate" => "0",
        "z_coordinate" => "0",
        "room_type" => "standard",
        "is_public" => "true"
      }

      {:noreply, updated_socket} = MapHandlers.handle_validate_room(%{"room" => room_params}, socket)
      
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == :validate
      assert updated_socket.assigns.changeset.data.id == room.id
      assert updated_socket.assigns.changeset.errors != []
    end
  end

  describe "handle_save_room/2" do
    test "creates a new room when not editing" do
      socket = create_socket(%{
        editing: nil,
        changeset: nil,
        rooms: []
      })

      room_params = %{
        "name" => "New Room",
        "description" => "A new room",
        "x_coordinate" => "0",
        "y_coordinate" => "0",
        "z_coordinate" => "0",
        "room_type" => "standard",
        "is_public" => "true"
      }

      params = %{"room" => room_params}
      {:noreply, updated_socket} = MapHandlers.handle_save_room(params, socket)
      
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Room created successfully"
      assert length(updated_socket.assigns.rooms) == 1
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end

    test "updates an existing room when editing" do
      # Create a room for editing
      {:ok, room} = Shard.Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      changeset = Shard.Map.change_room(room)
      socket = create_socket(%{
        editing: :room,
        changeset: changeset,
        rooms: [room]
      })

      room_params = %{
        "id" => to_string(room.id),
        "name" => "Updated Room",
        "description" => "An updated room",
        "x_coordinate" => "0",
        "y_coordinate" => "0",
        "z_coordinate" => "0",
        "room_type" => "standard",
        "is_public" => "true"
      }

      params = %{"room" => room_params}
      {:noreply, updated_socket} = MapHandlers.handle_save_room(params, socket)
      
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Room updated successfully"
      assert updated_socket.assigns.rooms |> hd |> Map.get(:name) == "Updated Room"
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end

  describe "handle_save_door/2" do
    test "creates a new door when not editing" do
      # Create rooms for the door
      {:ok, room1} = Shard.Map.create_room(%{
        name: "Room 1",
        description: "First room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Shard.Map.create_room(%{
        name: "Room 2",
        description: "Second room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      socket = create_socket(%{
        editing: nil,
        changeset: nil,
        rooms: [room1, room2],
        doors: []
      })

      door_params = %{
        "from_room_id" => to_string(room1.id),
        "to_room_id" => to_string(room2.id),
        "direction" => "east",
        "door_type" => "standard",
        "is_locked" => "false"
      }

      params = %{"door" => door_params}
      {:noreply, updated_socket} = MapHandlers.handle_save_door(params, socket)
      
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Door created successfully"
      assert length(updated_socket.assigns.doors) == 1
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end

    test "updates an existing door when editing" do
      # Create rooms for the door
      {:ok, room1} = Shard.Map.create_room(%{
        name: "Room 1",
        description: "First room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Shard.Map.create_room(%{
        name: "Room 2",
        description: "Second room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      # Create a door for editing
      {:ok, door} = Shard.Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })

      changeset = Shard.Map.change_door(door)
      socket = create_socket(%{
        editing: :door,
        changeset: changeset,
        rooms: [room1, room2],
        doors: [door]
      })

      door_params = %{
        "id" => to_string(door.id),
        "from_room_id" => to_string(room1.id),
        "to_room_id" => to_string(room2.id),
        "direction" => "west",
        "door_type" => "standard",
        "is_locked" => "true"
      }

      params = %{"door" => door_params}
      {:noreply, updated_socket} = MapHandlers.handle_save_door(params, socket)
      
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Door updated successfully"
      assert updated_socket.assigns.doors |> hd |> Map.get(:direction) == "west"
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end

  describe "handle_validate_door/2" do
    test "validates door changeset when creating new door" do
      # Create rooms for the door
      {:ok, room1} = Shard.Map.create_room(%{
        name: "Room 1",
        description: "First room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Shard.Map.create_room(%{
        name: "Room 2",
        description: "Second room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      socket = create_socket(%{
        editing: nil,
        changeset: nil,
        rooms: [room1, room2]
      })

      door_params = %{
        "from_room_id" => to_string(room1.id),
        "to_room_id" => to_string(room2.id),
        "direction" => "",
        "door_type" => "standard",
        "is_locked" => "false"
      }

      {:noreply, updated_socket} = MapHandlers.handle_validate_door(%{"door" => door_params}, socket)
      
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == :validate
      assert updated_socket.assigns.changeset.errors != []
    end

    test "validates door changeset when editing existing door" do
      # Create rooms for the door
      {:ok, room1} = Shard.Map.create_room(%{
        name: "Room 1",
        description: "First room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Shard.Map.create_room(%{
        name: "Room 2",
        description: "Second room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      # Create a door for editing
      {:ok, door} = Shard.Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })

      changeset = Shard.Map.change_door(door)
      socket = create_socket(%{
        editing: :door,
        changeset: changeset,
        rooms: [room1, room2]
      })

      door_params = %{
        "id" => to_string(door.id),
        "from_room_id" => to_string(room1.id),
        "to_room_id" => to_string(room2.id),
        "direction" => "",
        "door_type" => "standard",
        "is_locked" => "true"
      }

      {:noreply, updated_socket} = MapHandlers.handle_validate_door(%{"door" => door_params}, socket)
      
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == :validate
      assert updated_socket.assigns.changeset.data.id == door.id
      assert updated_socket.assigns.changeset.errors != []
    end
  end

  describe "handle_cancel_room/2" do
    test "cancels room editing and clears changeset" do
      # Create a room for editing
      {:ok, room} = Shard.Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      changeset = Shard.Map.change_room(room)
      socket = create_socket(%{
        editing: :room,
        changeset: changeset
      })

      {:noreply, updated_socket} = MapHandlers.handle_cancel_room(%{}, socket)
      
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end

  describe "handle_zoom_in/2" do
    test "increases zoom level" do
      socket = create_socket(%{zoom: 1.0})

      {:noreply, updated_socket} = MapHandlers.handle_zoom_in(%{}, socket)
      
      assert updated_socket.assigns.zoom == 1.2
    end

    test "caps zoom level at maximum" do
      socket = create_socket(%{zoom: 5.0})

      {:noreply, updated_socket} = MapHandlers.handle_zoom_in(%{}, socket)
      
      assert updated_socket.assigns.zoom == 5.0
    end
  end

  describe "handle_apply_and_save/2" do
    test "updates room when viewing room details" do
      # Create a room for editing
      {:ok, room} = Shard.Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      changeset = Shard.Map.change_room(room)
      socket = create_socket(%{
        viewing: room,
        changeset: changeset,
        rooms: [room]
      })

      room_params = %{
        "name" => "Updated Room",
        "description" => "An updated room",
        "x_coordinate" => "0",
        "y_coordinate" => "0",
        "z_coordinate" => "0",
        "room_type" => "standard",
        "is_public" => "true"
      }

      params = %{"room" => room_params}
      {:noreply, updated_socket} = MapHandlers.handle_apply_and_save(params, socket)
      
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Room updated successfully"
      assert updated_socket.assigns.rooms |> hd |> Map.get(:name) == "Updated Room"
      assert updated_socket.assigns.viewing.name == "Updated Room"
      assert updated_socket.assigns.changeset.data.name == "Updated Room"
    end
  end

  describe "handle_generate_description/2" do
    test "generates description and updates changeset" do
      # Create a room for editing
      {:ok, room} = Shard.Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      changeset = Shard.Map.change_room(room)
      socket = create_socket(%{
        viewing: room,
        changeset: changeset
      })

      # Mock the AI module to return a successful response
      Mox.defmock(Shard.AIMock, for: Shard.AI)
      Application.put_env(:shard, :ai_module, Shard.AIMock)
      
      Shard.AIMock
      |> Mox.expect(:generate_room_description, fn _zone_desc, _surrounding_rooms -> 
        {:ok, "A beautifully generated description"}
      end)

      {:noreply, updated_socket} = MapHandlers.handle_generate_description(%{}, socket)
      
      assert updated_socket.assigns.changeset.changes.description == "A beautifully generated description"
    end

    test "handles AI generation error" do
      # Create a room for editing
      {:ok, room} = Shard.Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      changeset = Shard.Map.change_room(room)
      socket = create_socket(%{
        viewing: room,
        changeset: changeset
      })

      # Mock the AI module to return an error
      Mox.defmock(Shard.AIMock, for: Shard.AI)
      Application.put_env(:shard, :ai_module, Shard.AIMock)
      
      Shard.AIMock
      |> Mox.expect(:generate_room_description, fn _zone_desc, _surrounding_rooms -> 
        {:error, "AI service unavailable"}
      end)

      {:noreply, updated_socket} = MapHandlers.handle_generate_description(%{}, socket)
      
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) == "Failed to generate description: AI service unavailable"
    end
  end

  describe "handle_back_to_rooms/2" do
    test "changes tab to rooms" do
      socket = create_socket(%{tab: "room_details"})

      {:noreply, updated_socket} = MapHandlers.handle_back_to_rooms(%{}, socket)
      
      assert updated_socket.assigns.tab == "rooms"
    end
  end

  describe "handle_cancel_door/2" do
    test "cancels door editing and clears changeset" do
      # Create rooms for the door
      {:ok, room1} = Shard.Map.create_room(%{
        name: "Room 1",
        description: "First room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Shard.Map.create_room(%{
        name: "Room 2",
        description: "Second room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      # Create a door for editing
      {:ok, door} = Shard.Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })

      changeset = Shard.Map.change_door(door)
      socket = create_socket(%{
        editing: :door,
        changeset: changeset
      })

      {:noreply, updated_socket} = MapHandlers.handle_cancel_door(%{}, socket)
      
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end
end
