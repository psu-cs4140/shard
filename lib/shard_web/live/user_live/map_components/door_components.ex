defmodule ShardWeb.UserLive.MapComponents.DoorComponents do
  @moduledoc """
  Components for rendering doors in maps and minimaps.
  """

  use ShardWeb, :live_view
  import ShardWeb.UserLive.MinimapComponents
  import ShardWeb.UserLive.MapComponents.RoomComponents

  # Component for door lines in the full map
  def door_line_full(assigns) do
    assigns =
      if should_skip_render?(assigns.door) do
        assign(assigns, :skip_render, true)
      else
        prepare_door_line_full_assigns(assigns)
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

  # Helper function to prepare all assigns for full map door line rendering
  defp prepare_door_line_full_assigns(assigns) do
    from_room = assigns.door.from_room
    to_room = assigns.door.to_room

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

    is_one_way = ShardWeb.UserLive.MinimapComponents.one_way_door_check(assigns.door)
    is_diagonal = decide_diagonal_door(assigns.door)
    stroke_color = get_door_stroke_color(assigns.door, is_one_way)
    {stroke_width, stroke_dasharray} = get_full_map_door_stroke_style(is_diagonal)
    door_name = get_door_name(assigns.door)

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

  # Helper function to get stroke style for full map doors
  defp get_full_map_door_stroke_style(is_diagonal) do
    if is_diagonal do
      {"2", "4,3"}
    else
      {"3", nil}
    end
  end

  # Component for door lines in the minimap
  def door_line(assigns) do
    assigns =
      if should_skip_render?(assigns.door) do
        assign(assigns, :skip_render, true)
      else
        prepare_door_line_assigns(assigns)
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

  # Helper function to check if rendering should be skipped
  defp should_skip_render?(door) do
    from_room = door.from_room
    to_room = door.to_room

    from_room == nil or to_room == nil or
      from_room.x_coordinate == nil or from_room.y_coordinate == nil or
      to_room.x_coordinate == nil or to_room.y_coordinate == nil
  end

  # Helper function to prepare all assigns for door line rendering
  defp prepare_door_line_assigns(assigns) do
    from_room = assigns.door.from_room
    to_room = assigns.door.to_room

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

    is_one_way = ShardWeb.UserLive.MinimapComponents.one_way_door_check(assigns.door)
    is_diagonal = decide_diagonal_door(assigns.door)
    stroke_color = get_door_stroke_color(assigns.door, is_one_way)
    {stroke_width, stroke_dasharray} = get_door_stroke_style(is_diagonal)
    door_name = get_door_name(assigns.door)

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

  # Helper function to determine if a door is diagonal
  defp decide_diagonal_door(door) do
    door.direction in ["northeast", "northwest", "southeast", "southwest"]
  end

  # Helper function to get door stroke color based on type and status
  defp get_door_stroke_color(door, is_one_way) do
    cond do
      door.is_locked -> "#dc2626"
      is_one_way -> "#ec4899"
      special_door_type_color(door) -> special_door_type_color(door)
      door.key_required && door.key_required != "" -> "#f59e0b"
      true -> "#22c55e"
    end
  end

  # Helper function to get color for special door types
  defp special_door_type_color(door) do
    case door.door_type do
      "portal" -> "#8b5cf6"
      "gate" -> "#d97706"
      "locked_gate" -> "#991b1b"
      "secret" -> "#6b7280"
      _ -> nil
    end
  end

  # Helper function to get stroke style for doors
  defp get_door_stroke_style(is_diagonal) do
    if is_diagonal do
      {"1.5", "3,2"}
    else
      {"2", nil}
    end
  end

  # Helper function to get door name
  defp get_door_name(door) do
    door.name || "#{String.capitalize(door.door_type || "standard")} Door"
  end
end
