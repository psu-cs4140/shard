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

  # This file now only contains the basic structure and helper functions
  # All specific tests have been moved to their respective dedicated files:
  # - map_handlers_room_test.exs for room-related tests
  # - map_handlers_door_test.exs for door-related tests
  # - map_handlers_ui_test.exs for UI interaction tests
  # - map_handlers_map_test.exs for map generation/cleanup tests
end
