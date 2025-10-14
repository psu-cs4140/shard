defmodule ShardWeb.AdminLive.MapHandlersMapTest do
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

  describe "handle_generate_default_map/2" do
    test "generates a default 3x3 map with rooms and doors" do
      # Start with empty map
      Shard.Repo.delete_all(Shard.Map.Door)
      Shard.Repo.delete_all(Shard.Map.Room)

      socket = create_socket(%{rooms: [], doors: []})

      {:noreply, updated_socket} = MapHandlers.handle_generate_default_map(%{}, socket)

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) ==
               "Default 3x3 map generated successfully!"

      assert length(updated_socket.assigns.rooms) == 9
      assert length(updated_socket.assigns.doors) == 12

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
      assert length(Shard.Map.list_rooms()) > 0
      assert length(Shard.Map.list_doors()) > 0

      socket = create_socket(%{rooms: [room1, room2], doors: []})

      {:noreply, updated_socket} = MapHandlers.handle_delete_all_map_data(%{}, socket)

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) ==
               "All map data deleted successfully!"

      assert length(updated_socket.assigns.rooms) == 0
      assert length(updated_socket.assigns.doors) == 0

      # Verify database is empty
      assert length(Shard.Map.list_rooms()) == 0
      assert length(Shard.Map.list_doors()) == 0
    end
  end
end
