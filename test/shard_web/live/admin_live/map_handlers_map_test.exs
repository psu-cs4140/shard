defmodule ShardWeb.AdminLive.MapHandlersMapTest do
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

  describe "handle_generate_default_map/2" do
    test "generates a default 3x3 map with rooms and doors" do
      # Start with empty map
      Shard.Repo.delete_all(Shard.Map.Door)
      Shard.Repo.delete_all(Shard.Map.Room)

      socket = create_socket(%{rooms: [], doors: []})

      {:noreply, updated_socket} = MapHandlers.handle_generate_default_map(%{}, socket)

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) ==
               "Sample 3x3 map generated for this zone successfully!"

      assert length(updated_socket.assigns.rooms) == 9
      # In a 3x3 grid, each connection creates two doors (one in each direction)
      # Horizontal connections: 3 rows * 2 connections per row = 6
      # Vertical connections: 3 columns * 2 connections per column = 6
      # Total unique connections: 12, but with return doors: 24
      assert length(updated_socket.assigns.doors) == 24

      # Check that rooms have correct coordinates
      room_coords = Enum.map(updated_socket.assigns.rooms, &{&1.x_coordinate, &1.y_coordinate})
      expected_coords = for x <- 0..2, y <- 0..2, do: {x, y}
      assert Enum.sort(room_coords) == Enum.sort(expected_coords)

      # Check that center room is a safe zone
      center_room =
        Enum.find(updated_socket.assigns.rooms, &(&1.x_coordinate == 1 and &1.y_coordinate == 1))

      assert center_room.room_type == "safe_zone"
    end
  end

  describe "handle_delete_all_map_data/2" do
    test "deletes all rooms and doors" do
      # Create some rooms and doors
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

      {:ok, _door} =
        Shard.Map.create_door(%{
          from_room_id: room1.id,
          to_room_id: room2.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })

      # Verify we have data before deletion
      assert Shard.Map.list_rooms() != []
      assert Shard.Map.list_doors() != []

      socket = create_socket(%{rooms: [room1, room2], doors: []})

      {:noreply, updated_socket} = MapHandlers.handle_delete_all_map_data(%{}, socket)

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) ==
               "All map data deleted successfully!"

      assert updated_socket.assigns.rooms == []
      assert updated_socket.assigns.doors == []

      # Verify database is empty
      assert Shard.Map.list_rooms() == []
      assert Shard.Map.list_doors() == []
    end
  end
end
