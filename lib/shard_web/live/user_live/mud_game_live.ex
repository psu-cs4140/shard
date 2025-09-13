defmodule ShardWeb.MudGameLive do
  use ShardWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    # Initialize game state
    game_state = %{
      player_position: {5, 5}, # In future, we most likely want to grab this from the database.
      map_data: generate_sample_map(), #Also want to pull map data from database
      active_panel: nil
    }

    {:ok, assign(socket, game_state: game_state)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-gray-900 text-white">  <!-- "phx-window-keydown="keypress" -->
      <!-- Header -->
      <header class="bg-gray-800 p-4 shadow-lg">
        <h1 class="text-2xl font-bold">MUD Game</h1>
      </header>

      <!-- Main Content -->
      <div class="flex flex-1 overflow-hidden">
        <!-- Left Panel - Mini-map -->
        <div class="w-3/4 p-4 overflow-auto">
          <.minimap
            map_data={@game_state.map_data}
            player_position={@game_state.player_position}
          />
        </div>

        <!-- Right Panel - Controls -->
        <div class="w-1/4 bg-gray-800 p-4 flex flex-col space-y-4">
          <h2 class="text-xl font-semibold mb-4">Game Controls</h2>

          <.control_button
            text="Character Sheet"
            icon="hero-user"
            click="open_character_sheet"
          />

          <.control_button
            text="Inventory"
            icon="hero-shopping-bag"
            click="open_inventory"
          />

          <.control_button
            text="Quests"
            icon="hero-document-text"
            click="open_quests"
          />

          <.control_button
            text="Map"
            icon="hero-map"
            click="open_map"
          />

          <.control_button
            text="Settings"
            icon="hero-cog"
            click="open_settings"
          />
        </div>
      </div>

      <!-- Footer -->
      <footer class="bg-gray-800 p-2 text-center text-sm">
        <p>MUD Game v1.0</p>
      </footer>
    </div>
    """
  end

  @impl true
  def handle_event("open_character_sheet", _params, socket) do
    {:noreply, put_flash(socket, :info, "Opening character sheet...")}
  end

  def handle_event("open_inventory", _params, socket) do
    {:noreply, put_flash(socket, :info, "Opening inventory...")}
  end

  def handle_event("open_quests", _params, socket) do
    {:noreply, put_flash(socket, :info, "Opening quests...")}
  end

  def handle_event("open_map", _params, socket) do
    {:noreply, put_flash(socket, :info, "Opening full map...")}
  end

  def handle_event("open_settings", _params, socket) do
    {:noreply, put_flash(socket, :info, "Opening settings...")}
  end

  # Handle keypresses for navigation, inventory, etc.

  # def handle_event("keypress", %{"key" => key}, socket) do
  #   IO.inspect(key, "Key pressed")
  #   {:noreply, assign(socket, :info, "Handling keypress")}
  # end

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

  # Component for control buttons
  def control_button(assigns) do
    ~H"""
    <button
      phx-click={@click}
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
