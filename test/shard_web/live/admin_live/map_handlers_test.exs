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
end
