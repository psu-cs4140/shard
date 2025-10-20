defmodule ShardWeb.UserLive.MapComponents do
  # -- Helpers ----------------------------------------------------
  defp format_position({x, y}), do: "{#{x}, #{y}}"
  defp format_position({x, y, z}), do: "{#{x}, #{y}, #{z}}"
  defp format_position(other), do: inspect(other)

  use ShardWeb, :live_view
  alias Shard.Map, as: GameMap
  alias Shard.Repo
  import ShardWeb.UserLive.MinimapComponents
  import ShardWeb.UserLive.Components2

  def map(assigns) do
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

    # Calculate bounds and scaling for the map
    {bounds, scale_factor} = calculate_map_bounds(valid_rooms)

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
    <div
      class="fixed inset-0 flex items-center justify-center"
      style="background-color: rgba(0, 0, 0, 0.5);"
    >
      <div class="bg-gray-800 rounded-lg max-w-6xl w-full max-h-[90vh] overflow-y-auto">
        <div class="bg-gray-700 rounded-lg shadow-lg w-full mx-4 p-6" phx-click-away="hide_modal">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-2xl font-bold">World Map</h3>
            <button phx-click="hide_modal" class="text-gray-400 hover:text-white">
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>

          <div class="bg-gray-800 rounded-lg p-4">
            <!-- Database-driven SVG Map -->
            <div class="relative mx-auto mb-6" style="width: 600px; height: 400px;">
              <svg
                viewBox="0 0 600 400"
                class="w-full h-full border border-gray-600 bg-gray-900 rounded"
              >
                <!-- Grid lines for reference -->
                <defs>
                  <pattern id="grid" width="20" height="20" patternUnits="userSpaceOnUse">
                    <path
                      d="M 20 0 L 0 0 0 20"
                      fill="none"
                      stroke="#374151"
                      stroke-width="0.5"
                      opacity="0.3"
                    />
                  </pattern>
                </defs>
                <rect width="100%" height="100%" fill="url(#grid)" />

    <!-- Render doors as lines first (so they appear behind rooms) -->
                <%= for door <- @doors do %>
                  <.door_line_full door={door} bounds={@bounds} scale_factor={@scale_factor} />
                <% end %>

    <!-- Render rooms as circles -->
                <%= for room <- @rooms do %>
                  <.room_circle_full
                    room={room}
                    is_player={@game_state.player_position == {room.x_coordinate, room.y_coordinate}}
                    bounds={@bounds}
                    scale_factor={@scale_factor}
                  />
                <% end %>

    <!-- Show player position even if no room exists there -->
                <%= if @game_state.player_position not in Enum.map(@rooms, &{&1.x_coordinate, &1.y_coordinate}) do %>
                  <.player_marker_full
                    position={@game_state.player_position}
                    bounds={@bounds}
                    scale_factor={@scale_factor}
                  />
                <% end %>
              </svg>
            </div>

            <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
              <!-- Current Location Info -->
              <div class="bg-gray-700 rounded-lg p-4">
                <h4 class="text-lg font-semibold mb-3 text-center">Current Location</h4>
                <div class="text-center">
                  <p class="text-xl font-bold text-blue-400 mb-2">
                    Position: {format_position(@game_state.player_position)}
                  </p>
                  <%= if @available_exits not in [nil, []] do %>
                    <div class="mt-3">
                      <h5 class="text-sm font-semibold mb-2">Available Exits:</h5>
                      <div class="grid grid-cols-2 gap-2">
                        <%= for exit <- @available_exits do %>
                          <button
                            phx-click="click_exit"
                            phx-value-dir={exit.direction}
                            class="bg-gray-600 hover:bg-gray-500 px-3 py-2 rounded text-center border border-gray-500 text-sm"
                            title={"Move " <> exit.direction}
                          >
                            {String.capitalize(exit.direction)}
                          </button>
                        <% end %>
                      </div>
                    </div>
                  <% else %>
                    <p class="text-gray-400 text-sm mt-2">No visible exits</p>
                  <% end %>
                </div>
              </div>

    <!-- Map Statistics -->
              <div class="bg-gray-700 rounded-lg p-4">
                <h4 class="text-lg font-semibold mb-3 text-center">Map Statistics</h4>
                <div class="space-y-2 text-sm">
                  <div class="flex justify-between">
                    <span>Total Rooms:</span>
                    <span class="font-mono">{@all_rooms_count}</span>
                  </div>
                  <div class="flex justify-between">
                    <span>Visible Rooms:</span>
                    <span class="font-mono">{length(@rooms)}</span>
                  </div>
                  <div class="flex justify-between">
                    <span>Total Doors:</span>
                    <span class="font-mono">{@all_doors_count}</span>
                  </div>
                  <div class="flex justify-between">
                    <span>Visible Doors:</span>
                    <span class="font-mono">{length(@doors)}</span>
                  </div>
                </div>
              </div>
            </div>

    <!-- Map Legend -->
            <div class="mt-6">
              <h4 class="text-lg font-semibold mb-4 text-center">Map Legend</h4>

              <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                <!-- Room Types -->
                <div class="bg-gray-700 rounded-lg p-3">
                  <h5 class="text-sm font-semibold mb-2">Room Types</h5>
                  <div class="space-y-1 text-xs">
                    <div class="flex items-center">
                      <div class="w-3 h-3 bg-blue-500 rounded-full mr-2"></div>
                      <span>Standard</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
                      <span>Safe Zone</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-3 bg-orange-500 rounded-full mr-2"></div>
                      <span>Shop</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-3 bg-red-800 rounded-full mr-2"></div>
                      <span>Dungeon</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-3 bg-yellow-500 rounded-full mr-2"></div>
                      <span>Treasure</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-3 h-3 bg-red-500 rounded-full mr-2"></div>
                      <span>Trap</span>
                    </div>
                  </div>
                </div>

    <!-- Door Types -->
                <div class="bg-gray-700 rounded-lg p-3">
                  <h5 class="text-sm font-semibold mb-2">Door Types</h5>
                  <div class="space-y-1 text-xs">
                    <div class="flex items-center">
                      <div class="w-4 h-0.5 bg-green-500 mr-2"></div>
                      <span>Standard</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-4 h-0.5 bg-orange-500 mr-2"></div>
                      <span>Gate</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-4 h-0.5 bg-purple-500 mr-2"></div>
                      <span>Portal</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-4 h-0.5 bg-gray-500 mr-2"></div>
                      <span>Secret</span>
                    </div>
                  </div>
                </div>

    <!-- Door Status -->
                <div class="bg-gray-700 rounded-lg p-3">
                  <h5 class="text-sm font-semibold mb-2">Door Status</h5>
                  <div class="space-y-1 text-xs">
                    <div class="flex items-center">
                      <div class="w-4 h-0.5 bg-red-600 mr-2"></div>
                      <span>Locked</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-4 h-0.5 bg-yellow-500 mr-2"></div>
                      <span>Key Required</span>
                    </div>
                    <div class="flex items-center">
                      <div class="w-4 h-0.5 bg-pink-500 mr-2"></div>
                      <span>One-way</span>
                    </div>
                    <div class="flex items-center">
                      <div
                        class="w-4 h-0.5 bg-green-500 border-dashed border-t mr-2"
                        style="border-top: 1px dashed #22c55e;"
                      >
                      </div>
                      <span>Diagonal</span>
                    </div>
                  </div>
                </div>

    <!-- Player Indicator -->
                <div class="bg-gray-700 rounded-lg p-3">
                  <h5 class="text-sm font-semibold mb-2">Indicators</h5>
                  <div class="space-y-1 text-xs">
                    <div class="flex items-center">
                      <div class="w-3 h-3 bg-red-500 ring-2 ring-red-300 rounded-full mr-2"></div>
                      <span>Your Location</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-4 text-center text-xs text-gray-400">
              <p>Tip: Arrow keys work for movement. Click exit buttons above to move.</p>
              <%= if length(@rooms) == 0 do %>
                <p class="text-yellow-400 mt-1">No rooms with coordinates found in database</p>
              <% end %>
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

  # Calculate bounds and scale factor for full map rendering
  defp calculate_map_bounds(rooms) do
    if Enum.empty?(rooms) do
      # Default bounds if no rooms - center around origin
      {{-5, -5, 5, 5}, 30.0}
    else
      x_coords = Enum.map(rooms, & &1.x_coordinate)
      y_coords = Enum.map(rooms, & &1.y_coordinate)

      min_x = Enum.min(x_coords)
      max_x = Enum.max(x_coords)
      min_y = Enum.min(y_coords)
      max_y = Enum.max(y_coords)

      # Add padding around the bounds
      padding = 2
      min_x = min_x - padding
      max_x = max_x + padding
      min_y = min_y - padding
      max_y = max_y + padding

      # Calculate scale to fit in 600x400 map with padding
      width = max_x - min_x
      height = max_y - min_y

      # Ensure minimum size to prevent division by zero
      width = max(width, 1)
      height = max(height, 1)

      # 560 to leave 20px padding on each side
      scale_x = 560 / width
      # 360 to leave 20px padding top/bottom
      scale_y = 360 / height
      scale_factor = min(scale_x, scale_y)

      # Ensure minimum scale factor for visibility
      scale_factor = max(scale_factor, 10.0)

      {{min_x, min_y, max_x, max_y}, scale_factor}
    end
  end

  # Calculate position within full map coordinates
  defp calculate_full_map_position({x, y}, {min_x, min_y, _max_x, _max_y}, scale_factor) do
    # Translate to origin and scale, then center in map
    scaled_x = (x - min_x) * scale_factor + 20
    scaled_y = (y - min_y) * scale_factor + 20

    # Ensure coordinates are within bounds
    scaled_x = max(10, min(scaled_x, 590))
    scaled_y = max(10, min(scaled_y, 390))

    {scaled_x, scaled_y}
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

  # Component for player marker in full map
  def player_marker_full(assigns) do
    {x_pos, y_pos} =
      calculate_full_map_position(
        assigns.position,
        assigns.bounds,
        assigns.scale_factor
      )

    assigns = assign(assigns, x_pos: x_pos, y_pos: y_pos)

    ~H"""
    <circle
      cx={@x_pos}
      cy={@y_pos}
      r="12"
      fill="#ef4444"
      stroke="#ffffff"
      stroke-width="3"
      opacity="0.9"
    >
      <title>Player at {format_position(@position)} (no room)</title>
    </circle>
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
