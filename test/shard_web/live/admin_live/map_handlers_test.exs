defmodule ShardWeb.AdminLive.MapHandlersTest do
  use ShardWeb.ConnCase, async: true
  alias ShardWeb.AdminLive.MapHandlers
  alias Shard.Map

  describe "handle_change_tab/2" do
    test "changes the tab correctly" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          tab: "rooms"
        }
      }

      params = %{"tab" => "doors"}
      {:noreply, updated_socket} = MapHandlers.handle_change_tab(params, socket)
      assert updated_socket.assigns.tab == "doors"
    end
  end

  describe "handle_new_room/2" do
    test "sets up a new room form" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          editing: nil,
          changeset: nil
        }
      }

      {:noreply, updated_socket} = MapHandlers.handle_new_room(%{}, socket)
      assert updated_socket.assigns.editing == :room
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == nil
    end
  end

  describe "handle_edit_room/2" do
    setup do
      # Create a room for editing
      {:ok, room} = Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room: room}
    end

    test "sets up an existing room for editing", %{room: room} do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          editing: nil,
          changeset: nil
        }
      }

      params = %{"id" => to_string(room.id)}
      {:noreply, updated_socket} = MapHandlers.handle_edit_room(params, socket)
      assert updated_socket.assigns.editing == :room
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.data.id == room.id
    end
  end

  describe "handle_delete_room/2" do
    setup do
      # Create a room for deletion
      {:ok, room} = Map.create_room(%{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room: room}
    end

    test "deletes a room successfully", %{room: room} do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          rooms: [room],
          doors: []
        }
      }

      params = %{"id" => to_string(room.id)}
      {:noreply, updated_socket} = MapHandlers.handle_delete_room(params, socket)
      assert get_flash(updated_socket, :info) == "Room deleted successfully"
      assert Enum.empty?(updated_socket.assigns.rooms)
    end
  end

  describe "handle_new_door/2" do
    test "sets up a new door form" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          editing: nil,
          changeset: nil
        }
      }

      {:noreply, updated_socket} = MapHandlers.handle_new_door(%{}, socket)
      assert updated_socket.assigns.editing == :door
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.action == nil
    end
  end

  describe "handle_edit_door/2" do
    setup do
      # Create rooms and a door for editing
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

      {:ok, door} = Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })

      {:ok, room1: room1, room2: room2, door: door}
    end

    test "sets up an existing door for editing", %{door: door} do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          editing: nil,
          changeset: nil
        }
      }

      params = %{"id" => to_string(door.id)}
      {:noreply, updated_socket} = MapHandlers.handle_edit_door(params, socket)
      assert updated_socket.assigns.editing == :door
      assert updated_socket.assigns.changeset != nil
      assert updated_socket.assigns.changeset.data.id == door.id
    end
  end

  describe "handle_delete_door/2" do
    setup do
      # Create rooms and a door for deletion
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

      {:ok, door} = Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })

      {:ok, room1: room1, room2: room2, door: door}
    end

    test "deletes a door successfully", %{door: door, room1: room1, room2: room2} do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          rooms: [room1, room2],
          doors: [door]
        }
      }

      params = %{"id" => to_string(door.id)}
      {:noreply, updated_socket} = MapHandlers.handle_delete_door(params, socket)
      assert get_flash(updated_socket, :info) == "Door deleted successfully"
      assert Enum.empty?(updated_socket.assigns.doors)
    end
  end

  describe "map interaction handlers" do
    test "handle_zoom_in/2 increases zoom level" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          zoom: 1.0
        }
      }

      {:noreply, updated_socket} = MapHandlers.handle_zoom_in(%{}, socket)
      assert updated_socket.assigns.zoom == 1.2
    end

    test "handle_zoom_out/2 decreases zoom level" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          zoom: 1.0
        }
      }

      {:noreply, updated_socket} = MapHandlers.handle_zoom_out(%{}, socket)
      assert updated_socket.assigns.zoom == 1.0 / 1.2
    end

    test "handle_reset_view/2 resets zoom and pan" do
      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          zoom: 2.0,
          pan_x: 100,
          pan_y: 50
        }
      }

      {:noreply, updated_socket} = MapHandlers.handle_reset_view(%{}, socket)
      assert updated_socket.assigns.zoom == 1.0
      assert updated_socket.assigns.pan_x == 0
      assert updated_socket.assigns.pan_y == 0
    end
  end
end
