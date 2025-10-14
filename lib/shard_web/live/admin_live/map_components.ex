defmodule ShardWeb.AdminLive.MapComponents do
  @moduledoc """
  UI components for the Map LiveView.
  Contains all rendering functions for tabs and visualizations.
  """
  use Phoenix.Component
  import ShardWeb.CoreComponents

  def rooms_tab(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <div class="mb-4">
        <.button phx-click="new_room" class="btn btn-primary">New Room</.button>
      </div>

      <%= if Enum.empty?(@rooms) do %>
        <div class="text-center py-8">
          <p class="text-gray-500">No rooms found.</p>
        </div>
      <% else %>
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>Name</th>
              <th>Coordinates</th>
              <th>Type</th>
              <th>Public</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for room <- @rooms do %>
              <tr>
                <td>{room.name}</td>
                <td>({room.x_coordinate}, {room.y_coordinate}, {room.z_coordinate})</td>
                <td>{room.room_type}</td>
                <td>{if room.is_public, do: "Yes", else: "No"}</td>
                <td class="flex space-x-2">
                  <.button phx-click="view_room" phx-value-id={room.id} class="btn btn-sm btn-info">
                    View
                  </.button>
                  <.button phx-click="edit_room" phx-value-id={room.id} class="btn btn-sm btn-primary">
                    Edit
                  </.button>
                  <.button
                    phx-click="delete_room"
                    phx-value-id={room.id}
                    class="btn btn-sm btn-error"
                    data-confirm="Are you sure?"
                  >
                    Delete
                  </.button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  def doors_tab(assigns) do
    # Sort doors so that each door is next to its return door
    sorted_doors = sort_doors_with_returns(@doors, @rooms)
    
    ~H"""
    <div class="overflow-x-auto">
      <div class="mb-4">
        <.button phx-click="new_door" class="btn btn-primary">New Door</.button>
      </div>

      <%= if Enum.empty?(@doors) do %>
        <div class="text-center py-8">
          <p class="text-gray-500">No doors found.</p>
        </div>
      <% else %>
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>From Room</th>
              <th>To Room</th>
              <th>Direction</th>
              <th>Type</th>
              <th>Locked</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for door <- sorted_doors do %>
              <% from_room = Enum.find(@rooms, &(&1.id == door.from_room_id)) %>
              <% to_room = Enum.find(@rooms, &(&1.id == door.to_room_id)) %>
              <tr class={if Map.get(door, :is_return_door), do: "bg-base-200", else: ""}>
                <td>{if from_room, do: from_room.name, else: "Unknown"}</td>
                <td>{if to_room, do: to_room.name, else: "Unknown"}</td>
                <td>{door.direction}</td>
                <td>{door.door_type}</td>
                <td>{if door.is_locked, do: "Yes", else: "No"}</td>
                <td class="flex space-x-2">
                  <.button phx-click="edit_door" phx-value-id={door.id} class="btn btn-sm btn-primary">
                    Edit
                  </.button>
                  <.button
                    phx-click="delete_door"
                    phx-value-id={door.id}
                    class="btn btn-sm btn-error"
                    data-confirm="Are you sure?"
                  >
                    Delete
                  </.button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  def map_visualization(assigns) do
    ~H"""
    <div class="bg-base-200 p-6 rounded-lg">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-xl font-bold">Map Visualization</h3>
        <div class="flex space-x-2">
          <.button phx-click="zoom_in" class="btn btn-sm">Zoom In</.button>
          <.button phx-click="zoom_out" class="btn btn-sm">Zoom Out</.button>
          <.button phx-click="reset_view" class="btn btn-sm">Reset View</.button>
        </div>
      </div>

      <%= if Enum.empty?(@rooms) do %>
        <div class="text-center py-8">
          <p class="text-gray-500">No rooms available to display.</p>
        </div>
      <% else %>
        <div
          class="relative overflow-hidden border border-base-300 rounded bg-base-100 cursor-move"
          style={"height: 600px; transform: scale(#{@zoom}); transform-origin: 0 0;"}
          id="map-container"
          phx-hook="MapDrag"
        >
          <div
            class="absolute inset-0"
            style={"transform: translate(#{@pan_x}px, #{@pan_y}px);"}
            id="map-content"
          >
            <!-- Render unique door connections to avoid duplication -->
            <%= for door <- get_unique_door_connections(@doors, @rooms) do %>
              <% from_room = Enum.find(@rooms, &(&1.id == door.from_room_id)) %>
              <% to_room = Enum.find(@rooms, &(&1.id == door.to_room_id)) %>
              <%= if from_room && to_room do %>
                <.door_connection from={from_room} to={to_room} />
              <% end %>
            <% end %>

            <%= for room <- @rooms do %>
              <div
                class={"absolute rounded border-2 flex items-center justify-center text-center p-1 #{room_classes(room)}"}
                style={"left: #{room.x_coordinate * 100}px; top: #{room.y_coordinate * 100}px; width: 80px; height: 80px;"}
              >
                <div>
                  <div class="font-bold text-xs truncate w-full">{room.name}</div>
                  <div class="text-xs mt-1">({room.x_coordinate}, {room.y_coordinate})</div>
                </div>
              </div>
            <% end %>
          </div>
        </div>

        <div class="mt-4 text-sm text-base-content">
          <p>Zoom: {Float.round(@zoom, 2)}x | Pan: ({@pan_x}, {@pan_y})</p>
          <p class="mt-2">Rooms: {Enum.count(@rooms)} | Doors: {Enum.count(@doors)}</p>
        </div>
      <% end %>
    </div>
    """
  end

  def room_details_tab(assigns) do
    ~H"""
    <div class="bg-base-200 p-6 rounded-lg">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-xl font-bold">Room Details: {@room.name}</h3>
        <.button phx-click="back_to_rooms" class="btn btn-secondary">Back to Rooms</.button>
      </div>

      <.simple_form
        :let={f}
        for={@changeset}
        id="room-details-form"
        phx-submit="apply_and_save"
      >
        <.input field={f[:name]} type="text" label="Name" required />
        <div class="flex items-end space-x-2">
          <div class="flex-grow">
            <.input field={f[:description]} type="textarea" label="Description" />
          </div>
          <.button phx-click="generate_description" class="btn btn-secondary" type="button">
            ✨ Generate with AI
          </.button>
        </div>
        <div class="grid grid-cols-3 gap-4">
          <.input field={f[:x_coordinate]} type="number" label="X Coordinate" />
          <.input field={f[:y_coordinate]} type="number" label="Y Coordinate" />
          <.input field={f[:z_coordinate]} type="number" label="Z Coordinate" />
        </div>
        <.input
          field={f[:room_type]}
          type="select"
          label="Type"
          prompt="Choose a type"
          options={[
            {"Standard", "standard"},
            {"Safe Zone", "safe_zone"},
            {"Shop", "shop"},
            {"Dungeon", "dungeon"},
            {"Treasure Room", "treasure_room"},
            {"Trap Room", "trap_room"}
          ]}
        />
        <.input field={f[:is_public]} type="checkbox" label="Public Room" />

        <div class="mt-6">
          <h4 class="text-lg font-bold mb-2">Doors Leading From This Room</h4>
          <%= if Enum.empty?(@doors_from) do %>
            <p class="text-gray-500">No doors lead from this room.</p>
          <% else %>
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>To Room</th>
                  <th>Direction</th>
                  <th>Type</th>
                  <th>Locked</th>
                </tr>
              </thead>
              <tbody>
                <%= for door <- @doors_from do %>
                  <tr>
                    <td>{door.to_room.name}</td>
                    <td>{door.direction}</td>
                    <td>{door.door_type}</td>
                    <td>{if door.is_locked, do: "Yes", else: "No"}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          <% end %>
        </div>

        <div class="mt-6">
          <h4 class="text-lg font-bold mb-2">Doors Leading To This Room</h4>
          <%= if Enum.empty?(@doors_to) do %>
            <p class="text-gray-500">No doors lead to this room.</p>
          <% else %>
            <table class="table table-zebra">
              <thead>
                <tr>
                  <th>From Room</th>
                  <th>Direction</th>
                  <th>Type</th>
                  <th>Locked</th>
                </tr>
              </thead>
              <tbody>
                <%= for door <- @doors_to do %>
                  <tr>
                    <td>{door.from_room.name}</td>
                    <td>{door.direction}</td>
                    <td>{door.door_type}</td>
                    <td>{if door.is_locked, do: "Yes", else: "No"}</td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          <% end %>
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." class="btn btn-primary">Apply and Save</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  defp door_connection(assigns) do
    from_x = assigns.from.x_coordinate * 100 + 40
    from_y = assigns.from.y_coordinate * 100 + 40
    to_x = assigns.to.x_coordinate * 100 + 40
    to_y = assigns.to.y_coordinate * 100 + 40

    assigns
    |> assign(:from_x, from_x)
    |> assign(:from_y, from_y)
    |> assign(:to_x, to_x)
    |> assign(:to_y, to_y)
    |> render_door_connection()
  end

  defp render_door_connection(assigns) do
    ~H"""
    <svg class="absolute inset-0 w-full h-full pointer-events-none">
      <line
        x1={@from_x}
        y1={@from_y}
        x2={@to_x}
        y2={@to_y}
        stroke="currentColor"
        stroke-width="2"
        stroke-dasharray="5,5"
        class="text-base-content/30"
      />
    </svg>
    """
  end

  defp room_classes(room) do
    base_classes = "flex flex-col items-center justify-center text-xs"

    type_classes =
      case room.room_type do
        "safe_zone" ->
          "bg-green-200 border-green-600 dark:bg-green-900/30 dark:border-green-500"

        "shop" ->
          "bg-blue-200 border-blue-600 dark:bg-blue-900/30 dark:border-blue-500"

        "dungeon" ->
          "bg-red-200 border-red-600 dark:bg-red-900/30 dark:border-red-500"

        "treasure_room" ->
          "bg-yellow-200 border-yellow-600 dark:bg-yellow-900/30 dark:border-yellow-500"

        "trap_room" ->
          "bg-pink-200 border-pink-600 dark:bg-pink-900/30 dark:border-pink-500"

        _ ->
          "bg-gray-200 border-gray-600 dark:bg-gray-700/30 dark:border-gray-500"
      end

    text_classes = "text-gray-800 dark:text-gray-200"

    "#{base_classes} #{type_classes} #{text_classes}"
  end

  # Helper function to get unique door connections for visualization
  # This prevents showing duplicate lines for bidirectional doors
  defp get_unique_door_connections(doors, rooms) do
    doors
    |> Enum.reduce({MapSet.new(), []}, fn door, {seen_pairs, unique_doors} ->
      from_room = Enum.find(rooms, &(&1.id == door.from_room_id))
      to_room = Enum.find(rooms, &(&1.id == door.to_room_id))

      if from_room && to_room do
        # Create a normalized pair identifier (smaller ID first)
        pair_key =
          case {from_room.id, to_room.id} do
            {a, b} when a < b -> {a, b}
            {a, b} -> {b, a}
          end

        if MapSet.member?(seen_pairs, pair_key) do
          {seen_pairs, unique_doors}
        else
          {MapSet.put(seen_pairs, pair_key), [door | unique_doors]}
        end
      else
        {seen_pairs, unique_doors}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  # Sort doors so that each door is next to its return door
  defp sort_doors_with_returns(doors, rooms) do
    # Create a map of door_id to door for quick lookup
    door_map = Enum.into(doors, %{}, &{&1.id, &1})
    
    # Create a map of {to_room_id, from_room_id, opposite_direction} to door_id for finding return doors
    door_lookup = 
      Enum.into(doors, %{}, fn door ->
        opposite_dir = Shard.Map.Door.opposite_direction(door.direction)
        key = {door.to_room_id, door.from_room_id, opposite_dir}
        {key, door.id}
      end)
    
    # Process doors to pair them with their return doors
    {processed_doors, _seen_ids} = 
      Enum.reduce(doors, {[], MapSet.new()}, fn door, {acc, seen} ->
        # Skip if this door was already processed
        if MapSet.member?(seen, door.id) do
          {acc, seen}
        else
          # Find the return door
          opposite_dir = Shard.Map.Door.opposite_direction(door.direction)
          return_door_key = {door.to_room_id, door.from_room_id, opposite_dir}
          return_door_id = Map.get(door_lookup, return_door_key)
          
          if return_door_id && (return_door = Map.get(door_map, return_door_id)) do
            # Mark both doors as processed
            new_seen = MapSet.put(seen, door.id) |> MapSet.put(return_door_id)
            # Add both doors to the result (door first, then its return)
            {acc ++ [door, Map.put(return_door, :is_return_door, true)], new_seen}
          else
            # No return door found, add just this door
            {acc ++ [door], MapSet.put(seen, door.id)}
          end
        end
      end)
    
    processed_doors
  end
end
