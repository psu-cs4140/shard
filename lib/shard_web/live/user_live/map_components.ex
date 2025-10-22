defmodule ShardWeb.UserLive.MapComponents do
  # -- Helpers ----------------------------------------------------
  defp format_position({x, y}), do: "{#{x}, #{y}}"
  defp format_position({x, y, z}), do: "{#{x}, #{y}, #{z}}"
  defp format_position(other), do: inspect(other)

  use ShardWeb, :live_view
  alias Shard.Map, as: GameMap
  alias Shard.Repo
  import ShardWeb.UserLive.MinimapComponents
  import ShardWeb.UserLive.LegacyMap
  import ShardWeb.UserLive.Components2

  def map(assigns) do
    ~H"""
    <div
      class="fixed inset-0 flex items-center justify-center"
      style="background-color: rgba(0, 0, 0, 0.5);"
    >
      <div class="bg-gray-800 rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="bg-gray-700 rounded-lg shadow-lg w-full mx-4 p-6" phx-click-away="hide_modal">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-2xl font-bold">World Map</h3>
            <button phx-click="hide_modal" class="text-gray-400 hover:text-white">
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>

          <div class="bg-gray-800 rounded-lg p-4">
            <div class="grid grid-cols-11 gap-0.5 mx-auto w-fit">
              <%= for {row, y} <- Enum.with_index(@game_state.map_data) do %>
                <%= for {cell, x} <- Enum.with_index(row) do %>
                  <.map_cell_legacy
                    cell={cell}
                    is_player={@game_state.player_position == {x, y}}
                    x={x}
                    y={y}
                  />
                <% end %>
              <% end %>
            </div>

            <div class="mt-6">
              <h4 class="text-lg font-semibold mb-2">Map Legend</h4>

              <div class="bg-gray-800 rounded-lg p-4 mt-4">
                <h4 class="text-lg font-semibold mb-3 text-center">Exits</h4>

                <%= if @available_exits in [nil, []] do %>
                  <div class="text-center text-gray-400">No visible exits</div>
                <% else %>
                  <div class="grid grid-cols-2 gap-2">
                    <%= for exit <- @available_exits do %>
                      <button
                        phx-click="click_exit"
                        phx-value-dir={exit.direction}
                        class="bg-gray-700 hover:bg-gray-600 px-3 py-2 rounded text-center border border-gray-600"
                        title={"Move " <> exit.direction}
                      >
                        {String.capitalize(exit.direction)}
                      </button>
                    <% end %>
                  </div>
                <% end %>

                <div class="text-xs text-gray-400 mt-2 text-center">
                  Tip: Arrow keys still work for movement.
                </div>
              </div>

              <div class="grid grid-cols-2 md:grid-cols-3 gap-2">
                <!-- Room Types -->
                <div class="flex items-center">
                  <div class="w-4 h-4 bg-blue-500 rounded-full mr-2"></div>
                  <span class="text-sm">Standard</span>
                </div>
                <div class="flex items-center">
                  <div class="w-4 h-4 bg-green-500 rounded-full mr-2"></div>
                  <span class="text-sm">Safe Zone</span>
                </div>
                <div class="flex items-center">
                  <div class="w-4 h-4 bg-orange-500 rounded-full mr-2"></div>
                  <span class="text-sm">Shop</span>
                </div>
                <div class="flex items-center">
                  <div class="w-4 h-4 bg-red-800 rounded-full mr-2"></div>
                  <span class="text-sm">Dungeon</span>
                </div>
                <div class="flex items-center">
                  <div class="w-4 h-4 bg-yellow-500 rounded-full mr-2"></div>
                  <span class="text-sm">Treasure</span>
                </div>
                <div class="flex items-center">
                  <div class="w-4 h-4 bg-red-500 rounded-full mr-2"></div>
                  <span class="text-sm">Trap</span>
                </div>
                <div class="flex items-center">
                  <div class="w-4 h-4 bg-red-500 ring-2 ring-red-300 rounded-full mr-2"></div>
                  <span class="text-sm">Player</span>
                </div>
                
    <!-- Door Types -->
                <div class="col-span-2 md:col-span-3 mt-2">
                  <h5 class="text-sm font-semibold mb-1">Door Types:</h5>
                  <div class="grid grid-cols-2 md:grid-cols-3 gap-1 text-xs">
                    <div class="flex items-center">
                      <div class="w-3 h-0.5 bg-green-500 mr-1"></div>
                      <span>Standard</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-0.5 bg-orange-500 mr-1"></div>
                      <span>Gate</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-0.5 bg-purple-500 mr-1"></div>
                      <span>Portal</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-0.5 bg-gray-500 mr-1"></div>
                      <span>Secret</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-0.5 bg-red-600 mr-1"></div>
                      <span>Locked</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-0.5 bg-yellow-500 mr-1"></div>
                      <span>Key Req.</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-0.5 bg-pink-500 mr-1"></div>
                      <span>One-way</span>
                    </div>
                    <div class="flex items-center">
                      <div
                        class="w-3 h-0.5 bg-green-500 border-dashed border-t mr-1"
                        style="border-top: 1.5px dashed #22c55e;"
                      >
                      </div>
                      <span>Diagonal</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-4 text-center">
              <p class="text-lg">Current Position: {format_position(@game_state.player_position)}</p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Component for the minimap
  def minimap(assigns) do
    # Get rooms and doors from database for dynamic rendering
    rooms = Repo.all(GameMap.Room) |> Repo.preload([:doors_from, :doors_to])
    doors = Repo.all(GameMap.Door) |> Repo.preload([:from_room, :to_room])

    # Filter out rooms without coordinates
    valid_rooms =
      Enum.filter(rooms, fn room ->
        room.x_coordinate != nil and room.y_coordinate != nil
      end)

    # Filter out doors without valid room connections
    valid_doors =
      Enum.filter(doors, fn door ->
        door.from_room && door.to_room &&
          door.from_room.x_coordinate != nil && door.from_room.y_coordinate != nil &&
          door.to_room.x_coordinate != nil && door.to_room.y_coordinate != nil
      end)

    # Calculate bounds and scaling for the minimap
    {bounds, scale_factor} = calculate_minimap_bounds(valid_rooms)

    assigns =
      assign(assigns,
        rooms: valid_rooms,
        doors: valid_doors,
        bounds: bounds,
        scale_factor: scale_factor,
        all_rooms_count: length(rooms),
        all_doors_count: length(doors)
      )

    ~H"""
    <div class="bg-gray-700 rounded-lg p-4 shadow-xl">
      <h2 class="text-xl font-semibold mb-4 text-center">Minimap</h2>
      <div class="relative mx-auto" style="width: 300px; height: 200px;">
        <svg viewBox="0 0 300 200" class="w-full h-full border border-gray-600 bg-gray-800">
          <!-- Render doors as lines first (so they appear behind rooms) -->
          <%= for door <- @doors do %>
            <.door_line door={door} bounds={@bounds} scale_factor={@scale_factor} />
          <% end %>
          
    <!-- Render rooms as circles -->
          <%= for room <- @rooms do %>
            <.room_circle
              room={room}
              is_player={@player_position == {room.x_coordinate, room.y_coordinate}}
              bounds={@bounds}
              scale_factor={@scale_factor}
            />
          <% end %>
          
    <!-- Show player position even if no room exists there -->
          <%= if @player_position not in Enum.map(@rooms, &{&1.x_coordinate, &1.y_coordinate}) do %>
            <.player_marker
              position={@player_position}
              bounds={@bounds}
              scale_factor={@scale_factor}
            />
          <% end %>
        </svg>
      </div>
      <div class="mt-4 text-center text-sm text-gray-300">
        <p>Player Position: {format_position(@player_position)}</p>
        <p class="text-xs mt-1">
          Showing: {length(@rooms)}/{@all_rooms_count} rooms | {length(@doors)}/{@all_doors_count} doors
        </p>
        <%= if length(@rooms) == 0 do %>
          <p class="text-xs text-yellow-400 mt-1">No rooms with coordinates found in database</p>
        <% end %>
      </div>
    </div>
    """
  end

  # Component for individual room circles in the minimap
  def room_circle(assigns) do
    assigns =
      if should_skip_room_render?(assigns.room) do
        assign(assigns, :skip_render, true)
      else
        prepare_room_circle_assigns(assigns)
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

  # Helper function to check if room should be skipped
  defp should_skip_room_render?(room) do
    room.x_coordinate == nil or room.y_coordinate == nil
  end

  # Helper function to prepare all room circle assigns
  defp prepare_room_circle_assigns(assigns) do
    # Calculate position within the minimap bounds
    {x_pos, y_pos} =
      calculate_minimap_position(
        {assigns.room.x_coordinate, assigns.room.y_coordinate},
        assigns.bounds,
        assigns.scale_factor
      )

    {fill_color, stroke_color} = get_room_colors(assigns.room.room_type)
    {player_stroke, player_width} = get_player_styling(assigns.is_player, stroke_color)

    assign(assigns,
      x_pos: x_pos,
      y_pos: y_pos,
      fill_color: fill_color,
      stroke_color: player_stroke,
      stroke_width: player_width,
      skip_render: false
    )
  end

  # Helper function to get room colors based on type
  defp get_room_colors(room_type) do
    case room_type do
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
  end

  # Helper function to get player-specific styling
  defp get_player_styling(is_player, default_stroke_color) do
    if is_player do
      {"#ef4444", "3"}
    else
      {default_stroke_color, "1"}
    end
  end

  # Component for door lines in the minimap
  def door_line(assigns) do
    # Use preloaded associations
    from_room = assigns.door.from_room
    to_room = assigns.door.to_room

    if should_skip_door_render?(from_room, to_room) do
      assigns = assign(assigns, :skip_render, true)
      render_door_line(assigns)
    else
      assigns = prepare_door_line_assigns(assigns, from_room, to_room)
      render_door_line(assigns)
    end
  end

  # Helper function to check if door should be skipped
  defp should_skip_door_render?(from_room, to_room) do
    from_room == nil or to_room == nil or
      from_room.x_coordinate == nil or from_room.y_coordinate == nil or
      to_room.x_coordinate == nil or to_room.y_coordinate == nil
  end

  # Helper function to prepare all door line assigns
  defp prepare_door_line_assigns(assigns, from_room, to_room) do
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
    is_diagonal = is_diagonal_door?(assigns.door)
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

  # Helper function to check if door is diagonal
  defp is_diagonal_door?(door) do
    door.direction in ["northeast", "northwest", "southeast", "southwest"]
  end

  # Helper function to determine door stroke color
  defp get_door_stroke_color(door, is_one_way) do
    cond do
      door.is_locked -> get_locked_door_color()
      is_one_way -> get_one_way_door_color()
      has_key_requirement?(door) -> get_key_required_door_color()
      true -> get_door_type_color(door.door_type)
    end
  end

  # Helper functions for door colors
  defp get_locked_door_color, do: "#dc2626"
  defp get_one_way_door_color, do: "#ec4899"
  defp get_key_required_door_color, do: "#f59e0b"

  defp has_key_requirement?(door) do
    door.key_required && door.key_required != ""
  end

  defp get_door_type_color(door_type) do
    case door_type do
      "portal" -> "#8b5cf6"
      "gate" -> "#d97706"
      "locked_gate" -> "#991b1b"
      "secret" -> "#6b7280"
      _ -> "#22c55e"
    end
  end

  # Helper function to get door stroke style
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

  # Helper function to render the door line template
  defp render_door_line(assigns) do
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
