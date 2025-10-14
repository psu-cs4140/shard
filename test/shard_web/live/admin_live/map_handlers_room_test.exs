defmodule ShardWeb.AdminLive.MapHandlersRoomTest do
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

    merged_assigns = Map.merge(default_assigns, assigns)
    
    # Create socket with proper assigns
    socket = %Socket{}
    Enum.reduce(merged_assigns, socket, fn {key, value}, acc ->
      Phoenix.LiveView.assign(acc, key, value)
    end)
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
      {:ok, room} =
        Shard.Map.create_room(%{
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
      {:ok, room} =
        Shard.Map.create_room(%{
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      # Create another room to ensure list functionality
      {:ok, room2} =
        Shard.Map.create_room(%{
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
      {:ok, room} =
        Shard.Map.create_room(%{
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

  describe "handle_validate_room/2" do
    test "validates room changeset when creating new room" do
      socket =
        create_socket(%{
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

      {:noreply, updated_socket} =
        MapHandlers.handle_validate_room(%{"room" => room_params}, socket)

      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == :validate
      assert updated_socket.assigns.changeset.errors != []
    end

    test "validates room changeset when editing existing room" do
      # Create a room for editing
      {:ok, room} =
        Shard.Map.create_room(%{
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      changeset = Shard.Map.change_room(room)

      socket =
        create_socket(%{
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

      {:noreply, updated_socket} =
        MapHandlers.handle_validate_room(%{"room" => room_params}, socket)

      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == :validate
      assert updated_socket.assigns.changeset.data.id == room.id
      assert updated_socket.assigns.changeset.errors != []
    end
  end

  describe "handle_save_room/2" do
    test "creates a new room when not editing" do
      socket =
        create_socket(%{
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
      {:ok, room} =
        Shard.Map.create_room(%{
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      changeset = Shard.Map.change_room(room)

      socket =
        create_socket(%{
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

  describe "handle_apply_and_save/2" do
    test "updates room when viewing room details" do
      # Create a room for editing
      {:ok, room} =
        Shard.Map.create_room(%{
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      changeset = Shard.Map.change_room(room)

      socket =
        create_socket(%{
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
      {:ok, room} =
        Shard.Map.create_room(%{
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      changeset = Shard.Map.change_room(room)

      socket =
        create_socket(%{
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

      assert updated_socket.assigns.changeset.changes.description ==
               "A beautifully generated description"
    end

    test "handles AI generation error" do
      # Create a room for editing
      {:ok, room} =
        Shard.Map.create_room(%{
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      changeset = Shard.Map.change_room(room)

      socket =
        create_socket(%{
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

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) ==
               "Failed to generate description: AI service unavailable"
    end
  end

  describe "handle_cancel_room/2" do
    test "cancels room editing and clears changeset" do
      # Create a room for editing
      {:ok, room} =
        Shard.Map.create_room(%{
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true
        })

      changeset = Shard.Map.change_room(room)

      socket =
        create_socket(%{
          editing: :room,
          changeset: changeset
        })

      {:noreply, updated_socket} = MapHandlers.handle_cancel_room(%{}, socket)

      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end

  describe "handle_back_to_rooms/2" do
    test "changes tab to rooms" do
      socket = create_socket(%{tab: "room_details"})

      {:noreply, updated_socket} = MapHandlers.handle_back_to_rooms(%{}, socket)

      assert updated_socket.assigns.tab == "rooms"
    end
  end
end
