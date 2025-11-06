defmodule ShardWeb.AdminLive.MapFunctionsTest do
  use Shard.DataCase, async: true
  alias ShardWeb.AdminLive.MapFunctions
  alias Phoenix.LiveView.Socket
  alias Shard.Map

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

  describe "save_room/2" do
    test "creates a new room when not editing" do
      # Get initial room count
      initial_room_count = length(Map.list_rooms())

      socket =
        create_socket(%{
          editing: nil,
          changeset: nil,
          rooms: []
        })

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
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Room created successfully"

      # Check that one more room was created
      assert length(updated_socket.assigns.rooms) == initial_room_count + 1
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end
end
