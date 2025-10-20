defmodule ShardWeb.UserLive.MapComponents.DoorComponents do
  @moduledoc """
  Components for rendering doors in maps and minimaps.
  """
  
  use ShardWeb, :live_view
  import ShardWeb.UserLive.MinimapComponents
  import ShardWeb.UserLive.MapComponents.RoomComponents

  # Component for door lines in the full map
  def door_line_full(assigns) do
    # Use preloaded associations
    from_room = assigns.door.from_room
    to_room = assigns.door.to_room

    return_early =
      from_room == nil or to_room == nil or
        from_room.x_coordinate == nil or from_room.y_coordinate == nil or
        to_room.x_coordinate == nil or to_room.y_coordinate == nil

    assigns =
      if return_early do
        assign(assigns, :skip_render, true)
      else
        {x1, y1} =
          calculate_full_map_position(
            {from_room.x_coordinate, from_room.y_coordinate},
            assigns.bounds,
            assigns.scale_factor
          )

        {x2, y2} =
          calculate_full_map_position(
            {to_room.x_coordinate, to_room.y_coordinate},
            assigns.bounds,
            assigns.scale_factor
          )

        # Check if this is a one-way door
        is_one_way = ShardWeb.UserLive.MinimapComponents.one_way_door_check(assigns.door)

        # Determine if this is a diagonal door
        is_diagonal =
          assigns.door.direction in ["northeast", "northwest", "southeast", "southwest"]

        # Color scheme based on door type and status
        stroke_color =
          cond do
            assigns.door.is_locked -> "#dc2626"
            is_one_way -> "#ec4899"
            assigns.door.door_type == "portal" -> "#8b5cf6"
            assigns.door.door_type == "gate" -> "#d97706"
            assigns.door.door_type == "locked_gate" -> "#991b1b"
            assigns.door.door_type == "secret" -> "#6b7280"
            assigns.door.key_required && assigns.door.key_required != "" -> "#f59e0b"
            true -> "#22c55e"
          end

        # Adjust stroke width and style for diagonal doors
        stroke_width = if is_diagonal, do: "2", else: "3"
        stroke_dasharray = if is_diagonal, do: "4,3", else: nil

        door_name =
          assigns.door.name || "#{String.capitalize(assigns.door.door_type || "standard")} Door"

        assign(assigns,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          stroke_color: stroke_color,
          stroke_width: stroke_width,
          stroke_dasharray: stroke_dasharray,
          door_name: door_name,
          is_diagonal: is_diagonal,
          skip_render: false
        )
      end

    ~H"""
    <%= unless @skip_render do %>
      <line
        x1={@x1}
        y1={@y1}
        x2={@x2}
        y2={@y2}
        stroke={@stroke_color}
        stroke-width={@stroke_width}
        stroke-dasharray={@stroke_dasharray}
        opacity="0.9"
      >
        <title>
          {@door_name} ({@door.direction}) - {String.capitalize(@door.door_type || "standard")}{if @is_diagonal,
            do: " (diagonal)",
            else: ""}
        </title>
      </line>
    <% end %>
    """
  end

  # Component for door lines in the minimap
  def door_line(assigns) do
    # Use preloaded associations
    from_room = assigns.door.from_room
    to_room = assigns.door.to_room

    return_early =
      from_room == nil or to_room == nil or
        from_room.x_coordinate == nil or from_room.y_coordinate == nil or
        to_room.x_coordinate == nil or to_room.y_coordinate == nil

    assigns =
      if return_early do
        assign(assigns, :skip_render, true)
      else
        {x1, y1} =
          calculate_minimap_position(
            {from_room.x_coordinate, from_room.y_coordinate},
            assigns.bounds,
            assigns.scale_factor
          )

        {x2, y2} =
          calculate_minimap_position(
            {to_room.x_coordinate, to_room.y_coordinate},
            assigns.bounds,
            assigns.scale_factor
          )

        # Check if this is a one-way door (no return door in opposite direction)
        is_one_way = ShardWeb.UserLive.MinimapComponents.one_way_door_check(assigns.door)

        # Determine if this is a diagonal door
        is_diagonal =
          assigns.door.direction in ["northeast", "northwest", "southeast", "southwest"]

        # Color scheme based on door type and status
        stroke_color =
          cond do
            # Red for locked doors
            assigns.door.is_locked -> "#dc2626"
            # Pink for one-way doors
            is_one_way -> "#ec4899"
            # Purple for portals
            assigns.door.door_type == "portal" -> "#8b5cf6"
            # Orange for gates
            assigns.door.door_type == "gate" -> "#d97706"
            # Dark red for locked gates
            assigns.door.door_type == "locked_gate" -> "#991b1b"
            # Gray for secret doors
            assigns.door.door_type == "secret" -> "#6b7280"
            # Orange for doors requiring keys
            assigns.door.key_required && assigns.door.key_required != "" -> "#f59e0b"
            # Green for standard doors
            true -> "#22c55e"
          end

        # Adjust stroke width and style for diagonal doors
        stroke_width = if is_diagonal, do: "1.5", else: "2"
        stroke_dasharray = if is_diagonal, do: "3,2", else: nil

        door_name =
          assigns.door.name || "#{String.capitalize(assigns.door.door_type || "standard")} Door"

        assign(assigns,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          stroke_color: stroke_color,
          stroke_width: stroke_width,
          stroke_dasharray: stroke_dasharray,
          door_name: door_name,
          is_diagonal: is_diagonal,
          skip_render: false
        )
      end

    ~H"""
    <%= unless @skip_render do %>
      <line
        x1={@x1}
        y1={@y1}
        x2={@x2}
        y2={@y2}
        stroke={@stroke_color}
        stroke-width={@stroke_width}
        stroke-dasharray={@stroke_dasharray}
        opacity="0.8"
      >
        <title>
          {@door_name} ({@door.direction}) - {String.capitalize(@door.door_type || "standard")}{if @is_diagonal,
            do: " (diagonal)",
            else: ""}
        </title>
      </line>
    <% end %>
    """
  end
end
