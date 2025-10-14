defmodule ShardWeb.AdminLive.MapHandlersUITest do
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
      __changed__: %{}
    }

    merged_assigns = :maps.merge(default_assigns, assigns)
    
    # Create socket with proper assigns
    %Socket{
      assigns: merged_assigns
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

  describe "handle_zoom_out/2" do
    test "decreases zoom level" do
      socket = create_socket(%{zoom: 1.0})

      {:noreply, updated_socket} = MapHandlers.handle_zoom_out(%{}, socket)

      assert updated_socket.assigns.zoom == 1.0 / 1.2
    end

    test "caps zoom level at minimum" do
      socket = create_socket(%{zoom: 0.2})

      {:noreply, updated_socket} = MapHandlers.handle_zoom_out(%{}, socket)

      assert updated_socket.assigns.zoom == 0.2
    end
  end

  describe "handle_reset_view/2" do
    test "resets zoom and pan to default values" do
      socket =
        create_socket(%{
          zoom: 2.5,
          pan_x: 100,
          pan_y: -50
        })

      {:noreply, updated_socket} = MapHandlers.handle_reset_view(%{}, socket)

      assert updated_socket.assigns.zoom == 1.0
      assert updated_socket.assigns.pan_x == 0
      assert updated_socket.assigns.pan_y == 0
    end
  end

  describe "handle_mousedown/2" do
    test "sets drag start coordinates" do
      socket = create_socket(%{drag_start: nil})
      params = %{"clientX" => 100, "clientY" => 200}

      {:noreply, updated_socket} = MapHandlers.handle_mousedown(params, socket)

      assert updated_socket.assigns.drag_start == %{x: 100, y: 200}
    end
  end

  describe "handle_mousemove/2" do
    test "updates pan coordinates when dragging" do
      socket =
        create_socket(%{
          drag_start: %{x: 100, y: 100},
          pan_x: 0,
          pan_y: 0
        })

      params = %{"clientX" => 150, "clientY" => 120}

      {:noreply, updated_socket} = MapHandlers.handle_mousemove(params, socket)

      assert updated_socket.assigns.pan_x == 50
      assert updated_socket.assigns.pan_y == 20
      assert updated_socket.assigns.drag_start == %{x: 150, y: 120}
    end

    test "does nothing when not dragging" do
      socket =
        create_socket(%{
          drag_start: nil,
          pan_x: 0,
          pan_y: 0
        })

      params = %{"clientX" => 150, "clientY" => 120}

      {:noreply, updated_socket} = MapHandlers.handle_mousemove(params, socket)

      assert updated_socket.assigns.pan_x == 0
      assert updated_socket.assigns.pan_y == 0
      assert updated_socket.assigns.drag_start == nil
    end
  end

  describe "handle_mouseup/2" do
    test "clears drag start coordinates" do
      socket = create_socket(%{drag_start: %{x: 100, y: 200}})

      {:noreply, updated_socket} = MapHandlers.handle_mouseup(%{}, socket)

      assert updated_socket.assigns.drag_start == nil
    end
  end

  describe "handle_mouseleave/2" do
    test "clears drag start coordinates" do
      socket = create_socket(%{drag_start: %{x: 100, y: 200}})

      {:noreply, updated_socket} = MapHandlers.handle_mouseleave(%{}, socket)

      assert updated_socket.assigns.drag_start == nil
    end
  end
end
