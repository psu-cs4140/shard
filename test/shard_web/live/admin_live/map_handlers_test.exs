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
end
