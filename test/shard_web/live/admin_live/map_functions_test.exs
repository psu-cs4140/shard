defmodule ShardWeb.AdminLive.MapFunctionsTest do
  use ShardWeb.ConnCase, async: true
  alias ShardWeb.AdminLive.MapFunctions
  alias Shard.Map
  alias Phoenix.LiveView.Socket

  # Helper function to create a socket with required assigns
  defp create_socket(assigns \\ %{}) do
    default_assigns = %{
      rooms: [],
      doors: [],
      editing: nil,
      changeset: nil,
      flash: %{}
    }

    merged_assigns = Map.merge(default_assigns, assigns)
    
    # Create socket with proper assigns
    %Socket{
      assigns: merged_assigns
    }
  end

  describe "save_room/2" do
    test "creates a new room when not editing" do
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
      assert length(updated_socket.assigns.rooms) == 1
      assert updated_socket.assigns.editing == nil
      assert updated_socket.assigns.changeset == nil
    end
  end
end
