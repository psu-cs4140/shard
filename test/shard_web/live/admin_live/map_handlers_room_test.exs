defmodule ShardWeb.AdminLive.MapHandlersRoomTest do
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
      # Create a zone first
      {:ok, zone} =
        Shard.Map.create_zone(%{
          name: "Test Zone",
          description: "A test zone",
          slug: "test-zone",
          min_level: 1,
          max_level: 10
        })

      # Create a room to delete
      {:ok, room} =
        Shard.Map.create_room(%{
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          zone_id: zone.id,
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
          zone_id: zone.id,
          room_type: "standard",
          is_public: true
        })

      socket = create_socket(%{rooms: [room, room2], doors: [], selected_zone_id: zone.id})

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
      initial_room_count = length(Shard.Map.list_rooms())

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
      assert length(updated_socket.assigns.rooms) == initial_room_count + 1
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil

      # Verify the room was actually created with the correct name
      created_room = Enum.find(updated_socket.assigns.rooms, &(&1.name == "New Room"))
      assert created_room != nil
      assert created_room.description == "A new room"
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
      updated_room = Enum.find(updated_socket.assigns.rooms, &(&1.id == room.id))
      assert updated_room.name == "Updated Room"
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
      updated_room = Enum.find(updated_socket.assigns.rooms, &(&1.id == room.id))
      assert updated_room.name == "Updated Room"
      assert updated_socket.assigns.viewing.name == "Updated Room"
      assert updated_socket.assigns.changeset.data.name == "Updated Room"
    end
  end

  # Note: These tests require an AI API key to run properly
  # describe "handle_generate_description/2" do
  #   test "generates description and updates changeset" do
  #     # Create a room for editing
  #     {:ok, room} =
  #       Shard.Map.create_room(%{
  #         name: "Test Room",
  #         description: "A test room",
  #         x_coordinate: 0,
  #         y_coordinate: 0,
  #         z_coordinate: 0,
  #         room_type: "standard",
  #         is_public: true
  #       })

  #     changeset = Shard.Map.change_room(room)

  #     socket =
  #       create_socket(%{
  #         viewing: room,
  #         changeset: changeset
  #       })

  #     # Mock the AI module to return a successful response
  #     # Since Shard.AI is not a behaviour, we'll use a different approach
  #     original_ai_module = Application.get_env(:shard, :ai_module, Shard.AI)
  #     Application.put_env(:shard, :ai_module, TestAIStub)

  #     # Define a test stub module
  #     defmodule TestAIStub do
  #       def generate_room_description(_zone_desc, _surrounding_rooms) do
  #         {:ok, "A beautifully generated description"}
  #       end
  #     end

  #     {:noreply, updated_socket} = MapHandlers.handle_generate_description(%{}, socket)

  #     # Restore original AI module
  #     Application.put_env(:shard, :ai_module, original_ai_module)

  #     # Check if the description is in the changes map
  #     assert Map.get(updated_socket.assigns.changeset.changes, :description) ==
  #              "A beautifully generated description"
  #   end

  #   test "handles AI generation error" do
  #     # Create a room for editing
  #     {:ok, room} =
  #       Shard.Map.create_room(%{
  #         name: "Test Room",
  #         description: "A test room",
  #         x_coordinate: 0,
  #         y_coordinate: 0,
  #         z_coordinate: 0,
  #         room_type: "standard",
  #         is_public: true
  #       })

  #     changeset = Shard.Map.change_room(room)

  #     socket =
  #       create_socket(%{
  #         viewing: room,
  #         changeset: changeset
  #       })

  #     # Mock the AI module to return an error
  #     # Since Shard.AI is not a behaviour, we'll use a different approach
  #     original_ai_module = Application.get_env(:shard, :ai_module, Shard.AI)
  #     Application.put_env(:shard, :ai_module, TestAIErrorStub)

  #     # Define a test stub module that returns an error
  #     defmodule TestAIErrorStub do
  #       def generate_room_description(_zone_desc, _surrounding_rooms) do
  #         {:error, "AI service unavailable"}
  #       end
  #     end

  #     {:noreply, updated_socket} = MapHandlers.handle_generate_description(%{}, socket)

  #     # Restore original AI module
  #     Application.put_env(:shard, :ai_module, original_ai_module)

  #     actual_error = Phoenix.Flash.get(updated_socket.assigns.flash, :error)
  #     assert actual_error =~ "Failed to generate description:"
  #     # Make the assertion more flexible to handle various error messages
  #     assert actual_error =~ "AI" or actual_error =~ "service"
  #   end
  # end

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
