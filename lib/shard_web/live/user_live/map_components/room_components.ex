defmodule ShardWeb.UserLive.MapComponents.RoomComponents do
  @moduledoc """
  Components for rendering rooms in maps and minimaps.
  """

  use ShardWeb, :live_view
  import ShardWeb.UserLive.MinimapComponents

  # Component for individual room circles in the minimap
  def room_circle(assigns) do
    return_early = assigns.room.x_coordinate == nil or assigns.room.y_coordinate == nil

    assigns =
      if return_early do
        assign(assigns, :skip_render, true)
      else
        # Calculate position within the minimap bounds
        {x_pos, y_pos} =
          calculate_minimap_position(
            {assigns.room.x_coordinate, assigns.room.y_coordinate},
            assigns.bounds,
            assigns.scale_factor
          )

        # Define colors for rooms based on room type
        {fill_color, stroke_color} =
          case assigns.room.room_type do
            # Green for safe zones
            "safe_zone" -> {"#10b981", "#34d399"}
            # Orange for shops
            "shop" -> {"#f59e0b", "#fbbf24"}
            # Dark red for dungeons
            "dungeon" -> {"#7c2d12", "#dc2626"}
            # Gold for treasure rooms
            "treasure_room" -> {"#eab308", "#facc15"}
            # Red for trap rooms
            "trap_room" -> {"#991b1b", "#ef4444"}
            # Blue for standard rooms
            _ -> {"#3b82f6", "#60a5fa"}
          end

        player_stroke = if assigns.is_player, do: "#ef4444", else: stroke_color
        player_width = if assigns.is_player, do: "3", else: "1"

        assign(assigns,
          x_pos: x_pos,
          y_pos: y_pos,
          fill_color: fill_color,
          stroke_color: player_stroke,
          stroke_width: player_width,
          skip_render: false
        )
      end

    ~H"""
    <%= unless @skip_render do %>
      <circle
        cx={@x_pos}
        cy={@y_pos}
        r="6"
        fill={@fill_color}
        stroke={@stroke_color}
        stroke-width={@stroke_width}
      >
        <title>
          {@room.name || "Room #{@room.id}"} ({@room.x_coordinate}, {@room.y_coordinate}) - {String.capitalize(
            @room.room_type || "standard"
          )}
        </title>
      </circle>
    <% end %>
    """
  end

  # Component for individual room circles in the full map
  def room_circle_full(assigns) do
    return_early = assigns.room.x_coordinate == nil or assigns.room.y_coordinate == nil

    assigns =
      if return_early do
        assign(assigns, :skip_render, true)
      else
        # Calculate position within the map bounds
        {x_pos, y_pos} =
          calculate_full_map_position(
            {assigns.room.x_coordinate, assigns.room.y_coordinate},
            assigns.bounds,
            assigns.scale_factor
          )

        # Define colors for rooms based on room type
        {fill_color, stroke_color} =
          case assigns.room.room_type do
            "safe_zone" -> {"#10b981", "#34d399"}
            "shop" -> {"#f59e0b", "#fbbf24"}
            "dungeon" -> {"#7c2d12", "#dc2626"}
            "treasure_room" -> {"#eab308", "#facc15"}
            "trap_room" -> {"#991b1b", "#ef4444"}
            _ -> {"#3b82f6", "#60a5fa"}
          end

        player_stroke = if assigns.is_player, do: "#ef4444", else: stroke_color
        player_width = if assigns.is_player, do: "4", else: "2"
        radius = if assigns.is_player, do: "12", else: "8"

        assign(assigns,
          x_pos: x_pos,
          y_pos: y_pos,
          fill_color: fill_color,
          stroke_color: player_stroke,
          stroke_width: player_width,
          radius: radius,
          skip_render: false
        )
      end

    ~H"""
    <%= unless @skip_render do %>
      <circle
        cx={@x_pos}
        cy={@y_pos}
        r={@radius}
        fill={@fill_color}
        stroke={@stroke_color}
        stroke-width={@stroke_width}
      >
        <title>
          {@room.name || "Room #{@room.id}"} ({@room.x_coordinate}, {@room.y_coordinate}) - {String.capitalize(
            @room.room_type || "standard"
          )}
        </title>
      </circle>
    <% end %>
    """
  end

  # Calculate position within full map coordinates
  def calculate_full_map_position({x, y}, {min_x, min_y, _max_x, _max_y}, scale_factor) do
    # Translate to origin and scale, then center in map
    scaled_x = (x - min_x) * scale_factor + 20
    scaled_y = (y - min_y) * scale_factor + 20

    # Ensure coordinates are within bounds
    scaled_x = max(10, min(scaled_x, 590))
    scaled_y = max(10, min(scaled_y, 390))

    {scaled_x, scaled_y}
  end
end
