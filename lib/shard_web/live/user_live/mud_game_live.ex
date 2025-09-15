defmodule ShardWeb.MudGameLive do
  use ShardWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Initialize game state
    game_state = %{
      player_position: {5, 5}, # In future, we most likely want to grab this from the database.
      map_data: generate_sample_map(), #Also want to pull map data from database
      active_panel: nil,
      player_stats: %{
        health: 100,
        max_health: 100,
        stamina: 100,
        max_stamina: 100,
        mana: 100,
        max_mana: 100
      },
      hotbar: %{
        slot_1: nil,
        slot_2: %{name: "Iron Sword", type: "weapon"},
        slot_3: nil,
        slot_4: %{name: "Health Potion", type: "consumable"},
        slot_5: nil
      }
    }

    terminal_state = %{
      output: [
        "Welcome to Shard!",
        "You find yourself in a mysterious dungeon.",
        "Type 'help' for available commands.",
        ""
      ],
      command_history: [],
      current_command: ""
    }

    # Controls what modal popup we are showing
    modal_state = %{
      show: false,
      type: 0
    }

    {:ok, assign(socket, game_state: game_state, terminal_state: terminal_state, modal_state: modal_state)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-gray-900 text-white" phx-window-keydown="keypress">  <!-- "phx-window-keydown="keypress" -->
      <!-- Header -->
      <header class="bg-gray-800 p-4 shadow-lg">
        <h1 class="text-2xl font-bold">MUD Game</h1>
      </header>

      <!-- Main Content -->
      <div class="flex flex-1 overflow-hidden">
        <!-- Left Panel - Terminal -->
        <div class="flex-1 p-4 flex flex-col">
          <.terminal
            terminal_state={@terminal_state}
          />
        </div>

        <!-- Right Panel - Controls -->
        <div class="w-100 bg-gray-800 px-4 py-4 flex flex-col space-y-4 overflow-y-auto" >
          <.minimap
            map_data={@game_state.map_data}
            player_position={@game_state.player_position}
          />

          <.player_stats
            stats={@game_state.player_stats}
            hotbar={@game_state.hotbar}
          />

          <h2 class="text-xl font-semibold mb-4">Game Controls</h2>

          <.control_button
            text="Character Sheet"
            icon="hero-user"
            click="open_modal"
            value="character_sheet"
          />

          <.control_button
            text="Inventory"
            icon="hero-shopping-bag"
            click="open_modal"
            value="inventory"
          />

          <.control_button
            text="Quests"
            icon="hero-document-text"
            click="open_modal"
            value="quests"
          />

          <.control_button
            text="Map"
            icon="hero-map"
            click="open_modal"
            value="map"
          />

          <.control_button
            text="Settings"
            icon="hero-cog"
            click="open_modal"
            value="settings"
          />

          <%!-- This is used to show char sheet, inventory, etc --%>
          <.character_sheet :if={@modal_state.show && @modal_state.type == "character_sheet"} />

          <.inventory :if={@modal_state.show && @modal_state.type == "inventory"} />

          <.quests :if={@modal_state.show && @modal_state.type == "quests"} />

          <.map :if={@modal_state.show && @modal_state.type == "map"} />

          <.settings :if={@modal_state.show && @modal_state.type == "settings"} />
        </div>
      </div>

      <!-- Footer -->
      <footer class="bg-gray-800 p-2 text-center text-sm">
        <p>MUD Game v1.0</p>
      </footer>
    </div>
    """
  end

  defp character_sheet(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center" style="background-color: rgba(0, 0, 0, 0.5);">
      <div class="bg-gray-800 rounded-lg max-w-4xl">
        <div class="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 p-6" phx-click-away="hide_modal">
  #       <h3 class="text-lg font-semibold mb-4">Modal Title</h3>
  #       <p class="mb-4">Your content here</p>
  #       <div class="flex justify-end">
  #         <button phx-click="hide_modal" class="px-4 py-2 bg-gray-200 rounded mr-2">Cancel</button>
  #         <button class="px-4 py-2 bg-blue-500 text-white rounded">Save</button>
  #       </div>
  #     </div>
      </div>
    </div>
    """
  end

  defp inventory(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center" style="background-color: rgba(0, 0, 0, 0.5);">
      <div class="bg-gray-800 rounded-lg max-w-4xl">
        <div class="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 p-6" phx-click-away="hide_modal">
  #       <h3 class="text-lg font-semibold mb-4">Modal Title</h3>
  #       <p class="mb-4">Your content here</p>
  #       <div class="flex justify-end">
  #         <button phx-click="hide_modal" class="px-4 py-2 bg-gray-200 rounded mr-2">Cancel</button>
  #         <button class="px-4 py-2 bg-blue-500 text-white rounded">Save</button>
  #       </div>
  #     </div>
      </div>
    </div>
    """
  end

  defp quests(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center" style="background-color: rgba(0, 0, 0, 0.5);">
      <div class="bg-gray-800 rounded-lg max-w-4xl">
        <div class="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 p-6" phx-click-away="hide_modal">
  #       <h3 class="text-lg font-semibold mb-4">Modal Title</h3>
  #       <p class="mb-4">Your content here</p>
  #       <div class="flex justify-end">
  #         <button phx-click="hide_modal" class="px-4 py-2 bg-gray-200 rounded mr-2">Cancel</button>
  #         <button class="px-4 py-2 bg-blue-500 text-white rounded">Save</button>
  #       </div>
  #     </div>
      </div>
    </div>
    """
  end

  defp map(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center" style="background-color: rgba(0, 0, 0, 0.5);">
      <div class="bg-gray-800 rounded-lg max-w-4xl">
        <div class="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 p-6" phx-click-away="hide_modal">
  #       <h3 class="text-lg font-semibold mb-4">Modal Title</h3>
  #       <p class="mb-4">Your content here</p>
  #       <div class="flex justify-end">
  #         <button phx-click="hide_modal" class="px-4 py-2 bg-gray-200 rounded mr-2">Cancel</button>
  #         <button class="px-4 py-2 bg-blue-500 text-white rounded">Save</button>
  #       </div>
  #     </div>
      </div>
    </div>
    """
  end

  defp settings(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center" style="background-color: rgba(0, 0, 0, 0.5);">
      <div class="bg-gray-800 rounded-lg max-w-4xl">
        <div class="bg-white rounded-lg shadow-lg max-w-md w-full mx-4 p-6" phx-click-away="hide_modal">
  #       <h3 class="text-lg font-semibold mb-4">Modal Title</h3>
  #       <p class="mb-4">Your content here</p>
  #       <div class="flex justify-end">
  #         <button phx-click="hide_modal" class="px-4 py-2 bg-gray-200 rounded mr-2">Cancel</button>
  #         <button class="px-4 py-2 bg-blue-500 text-white rounded">Save</button>
  #       </div>
  #     </div>
      </div>
    </div>
    """
  end

  # Component for individual hotbar slots
  def hotbar_slot(assigns) do
    ~H"""
    <div class="w-12 h-12 bg-gray-600 border-2 border-gray-500 rounded-lg flex items-center justify-center relative hover:border-gray-400 transition-colors">
      <!-- Slot number -->
      <span class="absolute top-0 left-1 text-xs text-gray-400"><%= @slot_number %></span>

      <!-- Item content -->
      <%= if @slot_data do %>
        <div class="text-center">
          <%= case @slot_data.type do %>
            <% "weapon" -> %>
              <.icon name="hero-sword" class="w-6 h-6 text-red-400" />
            <% "consumable" -> %>
              <.icon name="hero-beaker" class="w-6 h-6 text-green-400" />
            <% "armor" -> %>
              <.icon name="hero-shield-check" class="w-6 h-6 text-blue-400" />
            <% _ -> %>
              <.icon name="hero-cube" class="w-6 h-6 text-gray-400" />
          <% end %>
        </div>
        <!-- Tooltip on hover (item name) -->
        <div class="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-2 py-1 bg-gray-800 text-white text-xs rounded opacity-0 hover:opacity-100 transition-opacity pointer-events-none">
          <%= @slot_data.name %>
        </div>
      <% else %>
        <!-- Empty slot -->
        <div class="w-8 h-8 border border-dashed border-gray-500 rounded"></div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("open_modal", %{"modal" => modal_type}, socket) do
    {:noreply, assign(socket, modal_state: %{show: true, type: modal_type})}
  end

  def handle_event("hide_modal", _params, socket) do
    {:noreply, assign(socket, modal_state: %{show: false, type: ""})}
  end

  # Handle keypresses for navigation, inventory, etc.
  def handle_event("keypress", %{"key" => key}, socket) do
    IO.inspect(key, pretty: true)
    player_position = socket.assigns.game_state.player_position
    map_data = socket.assigns.game_state.map_data
    new_position = calc_position(player_position, key, map_data)

    # Add movement message to terminal if position changed
    terminal_state = if new_position != player_position do
      direction_name = case key do
        "ArrowUp" -> "north"
        "ArrowDown" -> "south"
        "ArrowRight" -> "east"
        "ArrowLeft" -> "west"
        _ -> nil
      end

      if direction_name do
        new_output = socket.assigns.terminal_state.output ++
                     ["You traversed #{direction_name}.", ""]
        Map.put(socket.assigns.terminal_state, :output, new_output)
      else
        socket.assigns.terminal_state
      end
    else
      socket.assigns.terminal_state
    end

    game_state = %{
      player_position: new_position,
      map_data: map_data,
      active_panel: nil,
      player_stats: socket.assigns.game_state.player_stats,
      hotbar: socket.assigns.game_state.hotbar
    }
    {:noreply, assign(socket, game_state: game_state, terminal_state: terminal_state)}
  end

  def handle_event("submit_command", %{"command" => %{"text" => command_text}}, socket) do
    trimmed_command = String.trim(command_text)

    if trimmed_command != "" do
      # Add command to history
      new_history = [trimmed_command | socket.assigns.terminal_state.command_history]

      # Process the command and get response and updated game state
      {response, updated_game_state} = process_command(trimmed_command, socket.assigns.game_state)

      # Add command and response to output
      new_output = socket.assigns.terminal_state.output ++
                   ["> #{trimmed_command}"] ++
                   response ++
                   [""]

      terminal_state = %{
        output: new_output,
        command_history: new_history,
        current_command: ""
      }

      {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_command", %{"command" => %{"text" => command_text}}, socket) do
    terminal_state = Map.put(socket.assigns.terminal_state, :current_command, command_text)
    {:noreply, assign(socket, terminal_state: terminal_state)}
  end

  #To calculate new player position on map
  def calc_position(curr_position, key, map_data) do
    new_position = case key do
      "ArrowUp" ->
        {elem(curr_position, 0), elem(curr_position, 1) - 1}
      "ArrowDown" ->
        {elem(curr_position, 0), elem(curr_position, 1) + 1}
      "ArrowRight" ->
        {elem(curr_position, 0) + 1, elem(curr_position, 1)}
      "ArrowLeft" ->
        {elem(curr_position, 0) - 1, elem(curr_position, 1)}
      _other  ->
        curr_position
    end

    # Check if the new position is valid (not a wall)
    if is_valid_position?(new_position, map_data) do
      new_position
    else
      curr_position
    end
  end

  # Helper function to check if a position is valid (not a wall and within bounds)
  defp is_valid_position?({x, y}, map_data) do
    # Check bounds
    if x < 0 or y < 0 or y >= length(map_data) or x >= length(Enum.at(map_data, 0)) do
      false
    else
      # Check if the tile is not a wall (0 represents walls)
      tile = map_data |> Enum.at(y) |> Enum.at(x)
      tile != 0
    end
  end

  # Component for player stats
  def player_stats(assigns) do
    ~H"""
    <div class="bg-gray-700 rounded-lg p-4 shadow-xl">
      <h2 class="text-xl font-semibold mb-4 text-center">Player Stats</h2>

      <!-- Health Bar -->
      <div class="mb-3">
        <div class="flex justify-between text-sm mb-1">
          <span class="text-red-400">Health</span>
          <span class="text-gray-300"><%= @stats.health %>/<%= @stats.max_health %></span>
        </div>
        <div class="w-full bg-gray-600 rounded-full h-3">
          <div
            class="bg-red-500 h-3 rounded-full transition-all duration-300"
            style={"width: #{(@stats.health / @stats.max_health * 100)}%"}
          >
          </div>
        </div>
      </div>

      <!-- Stamina Bar -->
      <div class="mb-3">
        <div class="flex justify-between text-sm mb-1">
          <span class="text-yellow-400">Stamina</span>
          <span class="text-gray-300"><%= @stats.stamina %>/<%= @stats.max_stamina %></span>
        </div>
        <div class="w-full bg-gray-600 rounded-full h-3">
          <div
            class="bg-yellow-500 h-3 rounded-full transition-all duration-300"
            style={"width: #{(@stats.stamina / @stats.max_stamina * 100)}%"}
          >
          </div>
        </div>
      </div>

      <!-- Mana Bar -->
      <div class="mb-3">
        <div class="flex justify-between text-sm mb-1">
          <span class="text-blue-400">Mana</span>
          <span class="text-gray-300"><%= @stats.mana %>/<%= @stats.max_mana %></span>
        </div>
        <div class="w-full bg-gray-600 rounded-full h-3">
          <div
            class="bg-blue-500 h-3 rounded-full transition-all duration-300"
            style={"width: #{(@stats.mana / @stats.max_mana * 100)}%"}
          >
          </div>
        </div>
      </div>

      <!-- Hotbar -->
      <div class="mt-4">
        <h3 class="text-lg font-semibold mb-2 text-center">Hotbar</h3>
        <div class="flex justify-center space-x-2">
          <%= for slot_num <- 1..5 do %>
            <.hotbar_slot
              slot_data={Map.get(@hotbar, String.to_atom("slot_#{slot_num}"))}
              slot_number={slot_num}
            />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Component for the minimap
  def minimap(assigns) do
    ~H"""
    <div class="bg-gray-700 rounded-lg p-4 shadow-xl">
      <h2 class="text-xl font-semibold mb-4 text-center">Minimap</h2>
      <div class="grid grid-cols-11 gap-0.5 mx-auto w-fit">
        <%= for {row, y} <- Enum.with_index(@map_data) do %>
          <%= for {cell, x} <- Enum.with_index(row) do %>
            <.map_cell
              cell={cell}
              is_player={@player_position == {x, y}}
              x={x}
              y={y}
            />
          <% end %>
        <% end %>
      </div>
      <div class="mt-4 text-center text-sm text-gray-300">
        <p>Player Position: <%= format_position(@player_position) %></p>
      </div>
    </div>
    """
  end

  # Component for individual map cells
  def map_cell(assigns) do
    # Define colors based on cell type
    color_class = case assigns.cell do
      0 -> "bg-gray-900"  # Wall
      1 -> "bg-green-700" # Floor
      2 -> "bg-blue-600"  # Water
      3 -> "bg-yellow-600" # Treasure
      _ -> "bg-purple-600" # Unknown
    end

    player_class = if assigns.is_player, do: "ring-2 ring-red-500", else: ""

    assigns = assign(assigns, color_class: color_class, player_class: player_class)

    ~H"""
    <div class={"w-6 h-6 #{assigns.color_class} #{assigns.player_class} border border-gray-800"}>
    </div>
    """
  end

  # Component for the terminal
  def terminal(assigns) do
    ~H"""
    <div class="flex flex-col h-full bg-black rounded-lg border border-gray-600">
      <!-- Terminal Header -->
      <div class="bg-gray-800 px-4 py-2 rounded-t-lg border-b border-gray-600">
        <h2 class="text-green-400 font-mono text-sm">MUD Terminal</h2>
      </div>

      <!-- Terminal Output -->
      <div class="flex-1 p-4 overflow-y-auto font-mono text-sm text-green-400 bg-black" id="terminal-output" phx-hook="TerminalScroll">
        <%= for line <- @terminal_state.output do %>
          <div class="whitespace-pre-wrap"><%= line %></div>
        <% end %>
      </div>

      <!-- Command Input -->
      <div class="p-4 border-t border-gray-600 bg-gray-900 rounded-b-lg">
        <.form for={%{}} as={:command} phx-submit="submit_command" phx-change="update_command" class="flex">
          <span class="text-green-400 font-mono mr-2">></span>
          <.input
            type="text"
            field={:text}
            name="command[text]"
            value={@terminal_state.current_command}
            placeholder="Enter command..."
            class="flex-1 bg-transparent border-none text-green-400 font-mono focus:ring-0 focus:outline-none p-0"
            autocomplete="off"
          />
        </.form>
      </div>
    </div>
    """
  end

  # Process terminal commands
  defp process_command(command, game_state) do
    case String.downcase(command) do
      "help" ->
        response = [
          "Available commands:",
          "  look - Examine your surroundings",
          "  stats - Show your character stats",
          "  position - Show your current position",
          "  inventory - Show your inventory (coming soon)",
          "  north/south/east/west - Move in that direction",
          "  help - Show this help message"
        ]
        {response, game_state}

      "look" ->
        {x, y} = game_state.player_position
        tile = game_state.map_data |> Enum.at(y) |> Enum.at(x)
        description = case tile do
          0 -> "You see a solid stone wall."
          1 -> "You are standing on a stone floor. The air is cool and damp."
          2 -> "You see clear blue water. It looks deep."
          3 -> "A glittering treasure chest sits here, beckoning you closer."
          _ -> "You see something strange and unidentifiable."
        end
        {[description], game_state}

      "stats" ->
        stats = game_state.player_stats
        response = [
          "Character Stats:",
          "  Health: #{stats.health}/#{stats.max_health}",
          "  Stamina: #{stats.stamina}/#{stats.max_stamina}",
          "  Mana: #{stats.mana}/#{stats.max_mana}"
        ]
        {response, game_state}

      "position" ->
        {x, y} = game_state.player_position
        {["You are at position (#{x}, #{y})."], game_state}

      "inventory" ->
        {["Your inventory is empty. (Feature coming soon!)"], game_state}

      cmd when cmd in ["north", "n"] ->
        execute_movement(game_state, "ArrowUp")

      cmd when cmd in ["south", "s"] ->
        execute_movement(game_state, "ArrowDown")

      cmd when cmd in ["east", "e"] ->
        execute_movement(game_state, "ArrowRight")

      cmd when cmd in ["west", "w"] ->
        execute_movement(game_state, "ArrowLeft")

      _ ->
        {["Unknown command: '#{command}'. Type 'help' for available commands."], game_state}
    end
  end

  # Execute movement command and update game state
  defp execute_movement(game_state, direction) do
    current_pos = game_state.player_position
    new_pos = calc_position(current_pos, direction, game_state.map_data)

    if new_pos == current_pos do
      response = ["You cannot move in that direction. There's a wall blocking your way."]
      {response, game_state}
    else
      direction_name = case direction do
        "ArrowUp" -> "north"
        "ArrowDown" -> "south"
        "ArrowRight" -> "east"
        "ArrowLeft" -> "west"
      end

      # Update game state with new position
      updated_game_state = %{game_state | player_position: new_pos}
      response = ["You traversed #{direction_name}."]

      {response, updated_game_state}
    end
  end

  # Component for control buttons
  def control_button(assigns) do
    ~H"""
    <button
      phx-click={@click}
      phx-value-modal={@value}
      class="w-full flex items-center justify-start gap-3 p-3 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500"
    >
      <.icon name={@icon} class="w-5 h-5" />
      <span><%= @text %></span>
    </button>
    """
  end

  # Helper function to format position tuple as string
  defp format_position({x, y}) do
    "{#{x}, #{y}}"
  end

  # Helper function to generate sample map data
  defp generate_sample_map() do
    # Generate an 11x11 map for display
    for y <- 0..10 do
      for x <- 0..10 do
        cond do
          x == 0 or y == 0 or x == 10 or y == 10 -> 0  # Walls around the edges
          x == 5 and y == 5 -> 3  # Treasure in the center
          x > 3 and x < 7 and y > 3 and y < 7 -> 1  # Central room floor
          rem(x, 3) == 0 and rem(y, 3) == 0 -> 2  # Water at intervals
          true -> 1  # Default floor
        end
      end
    end
  end
end
