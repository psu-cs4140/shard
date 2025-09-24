defmodule ShardWeb.MudGameLive do
  use ShardWeb, :live_view
  alias Shard.Map, as: GameMap
  alias Shard.Npcs.Npc
  alias Shard.Repo
  import Ecto.Query

  @impl true
  def mount(%{"map_id" => map_id}, _session, socket) do
    # Generate map data based on selected map
    map_data = generate_map_from_database(map_id)
    
    # Find a valid starting position (first floor tile found)
    starting_position = find_valid_starting_position(map_data)
    
    # Store the map_id for later use
    map_id = map_id
    
    # Initialize game state
    game_state = %{
      player_position: starting_position,
      map_data: map_data,
      map_id: map_id,
      active_panel: nil,
      player_stats: %{
        health: 100,
        max_health: 100,
        stamina: 100,
        max_stamina: 100,
        mana: 100,
        max_mana: 100,
        level: 5,
        experience: 1250,
        next_level_exp: 2000,
        strength: 15,
        dexterity: 12,
        intelligence: 10
      },
      inventory_items: [
        %{name: "Iron Sword", type: "weapon", damage: "1d8+3"},
        %{name: "Health Potion", type: "consumable", effect: "Restores 50 HP"},
        %{name: "Leather Armor", type: "armor", defense: 5},
        %{name: "Torch", type: "utility"},
        %{name: "Lockpick", type: "tool"}
      ],
      hotbar: %{
        slot_1: nil,
        slot_2: %{name: "Iron Sword", type: "weapon"},
        slot_3: nil,
        slot_4: %{name: "Health Potion", type: "consumable"},
        slot_5: nil
      },
      quests: [
        %{title: "The Lost Artifact", status: "In Progress", progress: "2/5 artifacts found"},
        %{title: "Clear the Dungeon", status: "Available", progress: "0/10 enemies slain"},
        %{title: "Merchant's Request", status: "Completed", progress: "Done"}
      ]
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
          <.character_sheet :if={@modal_state.show && @modal_state.type == "character_sheet"} game_state={@game_state} />

          <.inventory :if={@modal_state.show && @modal_state.type == "inventory"} game_state={@game_state} />

          <.quests :if={@modal_state.show && @modal_state.type == "quests"} game_state={@game_state} />

          <.map :if={@modal_state.show && @modal_state.type == "map"} game_state={@game_state} />

          <.settings :if={@modal_state.show && @modal_state.type == "settings"} game_state={@game_state} />
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
      <div class="bg-gray-800 rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="bg-gray-700 rounded-lg shadow-lg w-full mx-4 p-6" phx-click-away="hide_modal">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-2xl font-bold">Character Sheet</h3>
            <button phx-click="hide_modal" class="text-gray-400 hover:text-white">
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div class="bg-gray-800 rounded-lg p-4">
              <h4 class="text-lg font-semibold mb-3 text-center">Attributes</h4>
              <div class="space-y-2">
                <div class="flex justify-between">
                  <span>Level:</span>
                  <span class="font-mono"><%= @game_state.player_stats.level %></span>
                </div>
                <div class="flex justify-between">
                  <span>Strength:</span>
                  <span class="font-mono"><%= @game_state.player_stats.strength %></span>
                </div>
                <div class="flex justify-between">
                  <span>Dexterity:</span>
                  <span class="font-mono"><%= @game_state.player_stats.dexterity %></span>
                </div>
                <div class="flex justify-between">
                  <span>Intelligence:</span>
                  <span class="font-mono"><%= @game_state.player_stats.intelligence %></span>
                </div>
              </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-4">
              <h4 class="text-lg font-semibold mb-3 text-center">Experience</h4>
              <div class="mb-2">
                <div class="flex justify-between text-sm mb-1">
                  <span>EXP</span>
                  <span><%= @game_state.player_stats.experience %>/<%= @game_state.player_stats.next_level_exp %></span>
                </div>
                <div class="w-full bg-gray-600 rounded-full h-3">
                  <div
                    class="bg-purple-500 h-3 rounded-full"
                    style={"width: #{(@game_state.player_stats.experience / @game_state.player_stats.next_level_exp * 100)}%"}
                  >
                  </div>
                </div>
              </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-4 md:col-span-2">
              <h4 class="text-lg font-semibold mb-3 text-center">Combat Stats</h4>
              <div class="grid grid-cols-3 gap-4">
                <div class="text-center">
                  <div class="text-red-400">Health</div>
                  <div class="text-xl"><%= @game_state.player_stats.health %>/<%= @game_state.player_stats.max_health %></div>
                  <div class="w-full bg-gray-600 rounded-full h-2 mt-1">
                    <div
                      class="bg-red-500 h-2 rounded-full"
                      style={"width: #{(@game_state.player_stats.health / @game_state.player_stats.max_health * 100)}%"}
                    >
                    </div>
                  </div>
                </div>
                <div class="text-center">
                  <div class="text-yellow-400">Stamina</div>
                  <div class="text-xl"><%= @game_state.player_stats.stamina %>/<%= @game_state.player_stats.max_stamina %></div>
                  <div class="w-full bg-gray-600 rounded-full h-2 mt-1">
                    <div
                      class="bg-yellow-500 h-2 rounded-full"
                      style={"width: #{(@game_state.player_stats.stamina / @game_state.player_stats.max_stamina * 100)}%"}
                    >
                    </div>
                  </div>
                </div>
                <div class="text-center">
                  <div class="text-blue-400">Mana</div>
                  <div class="text-xl"><%= @game_state.player_stats.mana %>/<%= @game_state.player_stats.max_mana %></div>
                  <div class="w-full bg-gray-600 rounded-full h-2 mt-1">
                    <div
                      class="bg-blue-500 h-2 rounded-full"
                      style={"width: #{(@game_state.player_stats.mana / @game_state.player_stats.max_mana * 100)}%"}
                    >
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp inventory(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center" style="background-color: rgba(0, 0, 0, 0.5);">
      <div class="bg-gray-800 rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="bg-gray-700 rounded-lg shadow-lg w-full mx-4 p-6" phx-click-away="hide_modal">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-2xl font-bold">Inventory</h3>
            <button phx-click="hide_modal" class="text-gray-400 hover:text-white">
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <%= for item <- @game_state.inventory_items do %>
              <div class="bg-gray-800 rounded-lg p-4 flex items-center">
                <div class="mr-4">
                  <%= case item.type do %>
                    <% "weapon" -> %>
                      <.icon name="hero-sword" class="w-10 h-10 text-red-400" />
                    <% "armor" -> %>
                      <.icon name="hero-shield-check" class="w-10 h-10 text-blue-400" />
                    <% "consumable" -> %>
                      <.icon name="hero-beaker" class="w-10 h-10 text-green-400" />
                    <% "utility" -> %>
                      <.icon name="hero-light-bulb" class="w-10 h-10 text-yellow-400" />
                    <% "tool" -> %>
                      <.icon name="hero-wrench" class="w-10 h-10 text-purple-400" />
                    <% _ -> %>
                      <.icon name="hero-cube" class="w-10 h-10 text-gray-400" />
                  <% end %>
                </div>
                <div>
                  <div class="font-semibold"><%= item.name %></div>
                  <div class="text-sm text-gray-300 capitalize"><%= item.type %></div>
                  <%= if item[:damage] do %>
                    <div class="text-sm">Damage: <%= item.damage %></div>
                  <% end %>
                  <%= if item[:defense] do %>
                    <div class="text-sm">Defense: <%= item.defense %></div>
                  <% end %>
                  <%= if item[:effect] do %>
                    <div class="text-sm">Effect: <%= item.effect %></div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp quests(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center" style="background-color: rgba(0, 0, 0, 0.5);">
      <div class="bg-gray-800 rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="bg-gray-700 rounded-lg shadow-lg w-full mx-4 p-6" phx-click-away="hide_modal">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-2xl font-bold">Quests</h3>
            <button phx-click="hide_modal" class="text-gray-400 hover:text-white">
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>

          <div class="space-y-4">
            <%= for quest <- @game_state.quests do %>
              <div class="bg-gray-800 rounded-lg p-4">
                <div class="flex justify-between items-start">
                  <h4 class="text-lg font-semibold"><%= quest.title %></h4>
                  <span class={"px-2 py-1 rounded text-xs font-semibold " <>
                    case quest.status do
                      "Completed" -> "bg-green-500"
                      "In Progress" -> "bg-yellow-500"
                      "Available" -> "bg-blue-500"
                    end}>
                    <%= quest.status %>
                  </span>
                </div>
                <div class="mt-2">
                  <div class="flex justify-between text-sm mb-1">
                    <span>Progress</span>
                    <span><%= quest.progress %></span>
                  </div>
                  <%= if quest.status != "Completed" do %>
                    <div class="w-full bg-gray-600 rounded-full h-2">
                      <% progress_percent = case quest.status do
                        "In Progress" -> 40
                        "Available" -> 0
                        _ -> 100
                      end %>
                      <div
                        class="bg-green-500 h-2 rounded-full"
                        style={"width: #{progress_percent}%"}
                      >
                      </div>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp map(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center" style="background-color: rgba(0, 0, 0, 0.5);">
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
                      <div class="w-3 h-0.5 bg-green-500 border-dashed border-t mr-1" style="border-top: 1.5px dashed #22c55e;"></div>
                      <span>Diagonal</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div class="mt-4 text-center">
              <p class="text-lg">Current Position: <%= format_position(@game_state.player_position) %></p>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp settings(assigns) do
    ~H"""
    <div class="fixed inset-0 flex items-center justify-center" style="background-color: rgba(0, 0, 0, 0.5);">
      <div class="bg-gray-800 rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="bg-gray-700 rounded-lg shadow-lg w-full mx-4 p-6" phx-click-away="hide_modal">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-2xl font-bold">Settings</h3>
            <button phx-click="hide_modal" class="text-gray-400 hover:text-white">
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>

          <div class="space-y-6">
            <div class="bg-gray-800 rounded-lg p-4">
              <h4 class="text-lg font-semibold mb-3">Display Settings</h4>
              <div class="space-y-3">
                <div class="flex items-center justify-between">
                  <span>Fullscreen Mode</span>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" class="sr-only peer">
                    <div class="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>
                <div class="flex items-center justify-between">
                  <span>Terminal Text Size</span>
                  <select class="bg-gray-700 border border-gray-600 text-white rounded-lg p-2">
                    <option>Small</option>
                    <option selected>Medium</option>
                    <option>Large</option>
                  </select>
                </div>
              </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-4">
              <h4 class="text-lg font-semibold mb-3">Audio Settings</h4>
              <div class="space-y-3">
                <div class="flex items-center justify-between">
                  <span>Master Volume</span>
                  <input type="range" min="0" max="100" value="80" class="w-32">
                </div>
                <div class="flex items-center justify-between">
                  <span>Music Volume</span>
                  <input type="range" min="0" max="100" value="70" class="w-32">
                </div>
                <div class="flex items-center justify-between">
                  <span>Sound Effects</span>
                  <input type="range" min="0" max="100" value="90" class="w-32">
                </div>
              </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-4">
              <h4 class="text-lg font-semibold mb-3">Gameplay</h4>
              <div class="space-y-3">
                <div class="flex items-center justify-between">
                  <span>Enable Auto-Save</span>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" class="sr-only peer" checked>
                    <div class="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>
                <div class="flex items-center justify-between">
                  <span>Show Tutorial Tips</span>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" class="sr-only peer" checked>
                    <div class="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600"></div>
                  </label>
                </div>
              </div>
            </div>

            <div class="flex justify-end">
              <button phx-click="hide_modal" class="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg mr-2">
                Save Settings
              </button>
              <button phx-click="hide_modal" class="px-4 py-2 bg-gray-600 hover:bg-gray-700 rounded-lg">
                Cancel
              </button>
            </div>
          </div>
        </div>
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
      map_id: socket.assigns.game_state.map_id,
      active_panel: nil,
      player_stats: socket.assigns.game_state.player_stats,
      hotbar: socket.assigns.game_state.hotbar,
      inventory_items: socket.assigns.game_state.inventory_items,
      quests: socket.assigns.game_state.quests
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
  def calc_position(curr_position, key, _map_data) do
    new_position = case key do
      "ArrowUp" ->
        {elem(curr_position, 0), elem(curr_position, 1) - 1}
      "ArrowDown" ->
        {elem(curr_position, 0), elem(curr_position, 1) + 1}
      "ArrowRight" ->
        {elem(curr_position, 0) + 1, elem(curr_position, 1)}
      "ArrowLeft" ->
        {elem(curr_position, 0) - 1, elem(curr_position, 1)}
      "northeast" ->
        {elem(curr_position, 0) + 1, elem(curr_position, 1) - 1}
      "southeast" ->
        {elem(curr_position, 0) + 1, elem(curr_position, 1) + 1}
      "northwest" ->
        {elem(curr_position, 0) - 1, elem(curr_position, 1) - 1}
      "southwest" ->
        {elem(curr_position, 0) - 1, elem(curr_position, 1) + 1}
      _other  ->
        curr_position
    end

    # Check if the movement is valid (room exists or door connection exists)
    if is_valid_movement?(curr_position, new_position, key) do
      new_position
    else
      curr_position
    end
  end

  # Helper function to check if a position is valid (has a room or door connection)
  defp is_valid_position?({x, y}, _map_data) do
    # Check if there's a room at this position
    case GameMap.get_room_by_coordinates(x, y) do
      nil -> false  # No room exists at this position
      _room -> true  # Room exists, movement is valid
    end
  end

  # Helper function to check if movement is valid via door connection
  defp is_valid_movement?(current_pos, new_pos, direction) do
    {curr_x, curr_y} = current_pos
    {new_x, new_y} = new_pos
    
    # First check if there's a room at the current position
    current_room = GameMap.get_room_by_coordinates(curr_x, curr_y)
    
    case current_room do
      nil -> false  # No current room, can't move
      room ->
        # Check if there's a door in the specified direction from current room
        direction_str = case direction do
          "ArrowUp" -> "north"
          "ArrowDown" -> "south"
          "ArrowRight" -> "east"
          "ArrowLeft" -> "west"
          "northeast" -> "northeast"
          "southeast" -> "southeast"
          "northwest" -> "northwest"
          "southwest" -> "southwest"
          _ -> nil
        end
        
        if direction_str do
          door = GameMap.get_door_in_direction(room.id, direction_str)
          case door do
            nil -> 
              # No door, check if target position has a room
              is_valid_position?(new_pos, nil)
            door -> 
              # Check door accessibility based on type and status
              cond do
                door.is_locked -> 
                  IO.puts("Movement blocked: The #{door.door_type} is locked")
                  false
                door.door_type == "secret" ->
                  IO.puts("Movement blocked: Secret passage not discovered")
                  false
                true ->
                  # Door exists and is accessible, check if it leads to target position
                  target_room = GameMap.get_room!(door.to_room_id)
                  if target_room.x_coordinate == new_x and target_room.y_coordinate == new_y do
                    IO.puts("Moving through #{door.door_type} door")
                    true
                  else
                    false
                  end
              end
          end
        else
          false
        end
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
    # Get rooms and doors from database for dynamic rendering
    rooms = Repo.all(GameMap.Room) |> Repo.preload([:doors_from, :doors_to])
    doors = Repo.all(GameMap.Door) |> Repo.preload([:from_room, :to_room])
    
    # Filter out rooms without coordinates
    valid_rooms = Enum.filter(rooms, fn room -> 
      room.x_coordinate != nil and room.y_coordinate != nil 
    end)
    
    # Filter out doors without valid room connections
    valid_doors = Enum.filter(doors, fn door ->
      door.from_room && door.to_room &&
      door.from_room.x_coordinate != nil && door.from_room.y_coordinate != nil &&
      door.to_room.x_coordinate != nil && door.to_room.y_coordinate != nil
    end)
    
    # Calculate bounds and scaling for the minimap
    {bounds, scale_factor} = calculate_minimap_bounds(valid_rooms)
    
    assigns = assign(assigns, 
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
        <p>Player Position: <%= format_position(@player_position) %></p>
        <p class="text-xs mt-1">
          Showing: <%= length(@rooms) %>/<%= @all_rooms_count %> rooms | 
          <%= length(@doors) %>/<%= @all_doors_count %> doors
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
    
    assigns = if return_early do
      assign(assigns, :skip_render, true)
    else
      # Calculate position within the minimap bounds
      {x_pos, y_pos} = calculate_minimap_position(
        {assigns.room.x_coordinate, assigns.room.y_coordinate}, 
        assigns.bounds, 
        assigns.scale_factor
      )
      
      # Define colors for rooms based on room type
      {fill_color, stroke_color} = case assigns.room.room_type do
        "safe_zone" -> {"#10b981", "#34d399"}      # Green for safe zones
        "shop" -> {"#f59e0b", "#fbbf24"}           # Orange for shops
        "dungeon" -> {"#7c2d12", "#dc2626"}        # Dark red for dungeons
        "treasure_room" -> {"#eab308", "#facc15"}  # Gold for treasure rooms
        "trap_room" -> {"#991b1b", "#ef4444"}      # Red for trap rooms
        _ -> {"#3b82f6", "#60a5fa"}                # Blue for standard rooms
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
        <title><%= @room.name || "Room #{@room.id}" %> (<%= @room.x_coordinate %>, <%= @room.y_coordinate %>) - <%= String.capitalize(@room.room_type || "standard") %></title>
      </circle>
    <% end %>
    """
  end

  # Component for door lines in the minimap
  def door_line(assigns) do
    # Use preloaded associations
    from_room = assigns.door.from_room
    to_room = assigns.door.to_room
    
    return_early = from_room == nil or to_room == nil or 
                   from_room.x_coordinate == nil or from_room.y_coordinate == nil or
                   to_room.x_coordinate == nil or to_room.y_coordinate == nil
    
    assigns = if return_early do
      assign(assigns, :skip_render, true)
    else
      {x1, y1} = calculate_minimap_position(
        {from_room.x_coordinate, from_room.y_coordinate}, 
        assigns.bounds, 
        assigns.scale_factor
      )
      {x2, y2} = calculate_minimap_position(
        {to_room.x_coordinate, to_room.y_coordinate}, 
        assigns.bounds, 
        assigns.scale_factor
      )
      
      # Check if this is a one-way door (no return door in opposite direction)
      is_one_way = is_one_way_door?(assigns.door)
      
      # Determine if this is a diagonal door
      is_diagonal = assigns.door.direction in ["northeast", "northwest", "southeast", "southwest"]
      
      # Color scheme based on door type and status
      stroke_color = cond do
        assigns.door.is_locked -> "#dc2626"  # Red for locked doors
        is_one_way -> "#ec4899"  # Pink for one-way doors
        assigns.door.door_type == "portal" -> "#8b5cf6"  # Purple for portals
        assigns.door.door_type == "gate" -> "#d97706"  # Orange for gates
        assigns.door.door_type == "locked_gate" -> "#991b1b"  # Dark red for locked gates
        assigns.door.door_type == "secret" -> "#6b7280"  # Gray for secret doors
        assigns.door.key_required && assigns.door.key_required != "" -> "#f59e0b"  # Orange for doors requiring keys
        true -> "#22c55e"  # Green for standard doors
      end
      
      # Adjust stroke width and style for diagonal doors
      stroke_width = if is_diagonal, do: "1.5", else: "2"
      stroke_dasharray = if is_diagonal, do: "3,2", else: nil
      
      door_name = assigns.door.name || "#{String.capitalize(assigns.door.door_type || "standard")} Door"
      
      assign(assigns, 
        x1: x1, y1: y1, x2: x2, y2: y2, 
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
        <title><%= @door_name %> (<%= @door.direction %>) - <%= String.capitalize(@door.door_type || "standard") %><%= if @is_diagonal, do: " (diagonal)", else: "" %></title>
      </line>
    <% end %>
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
          <input
            type="text"
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
          "  npc - Show descriptions of NPCs in this room",
          "  talk \"npc_name\" - Talk to a specific NPC",
          "  north/south/east/west - Move in cardinal directions",
          "  northeast/southeast/northwest/southwest - Move diagonally",
          "  Shortcuts: n/s/e/w/ne/se/nw/sw",
          "  help - Show this help message"
        ]
        {response, game_state}

      "look" ->
        {x, y} = game_state.player_position
        
        # Get room from database
        room = GameMap.get_room_by_coordinates(x, y)
        
        # Build room description - always use predetermined descriptions for tutorial terrain
        room_description = if game_state.map_id == "tutorial_terrain" do
          # Provide tutorial-specific descriptions based on coordinates
          case {x, y} do
            {0, 0} -> "Tutorial Starting Chamber\nYou are in a small stone chamber with rough-hewn walls. Ancient torches mounted on iron brackets cast flickering light across the weathered stones. This appears to be the beginning of your adventure. You can see worn footprints in the dust, suggesting others have passed this way before."
            
            {1, 0} -> "Eastern Alcove\nA narrow alcove extends eastward from the starting chamber. The walls here are carved with simple symbols that seem to glow faintly in the torchlight. The air carries a hint of something ancient and mysterious."
            
            {0, 1} -> "Southern Passage\nA short passage leads south from the starting chamber. The stone floor is worn smooth by countless footsteps. Moisture drips steadily from somewhere in the darkness ahead."
            
            {1, 1} -> "Corner Junction\nYou stand at a junction where two passages meet. The walls here show signs of careful construction, with fitted stones and mortar still holding strong after unknown years. A cool breeze flows through the intersection."
            
            {5, 5} -> "Central Treasure Chamber\nYou stand in a magnificent circular chamber with a high vaulted ceiling. Ornate pillars support graceful arches, and in the center sits an elaborate treasure chest made of dark wood bound with brass. The chest gleams with an inner light, and precious gems are scattered around its base."
            
            {2, 2} -> "Training Grounds\nThis rectangular chamber appears to have been used for combat training. Wooden practice dummies stand against the walls, and the floor is marked with scuff marks from countless sparring sessions. Weapon racks line the eastern wall."
            
            {3, 3} -> "Meditation Garden\nA peaceful underground garden with carefully tended moss growing in geometric patterns on the floor. A small fountain in the center provides the gentle sound of flowing water. The air here feels calm and restorative."
            
            {4, 4} -> "Library Ruins\nThe remains of what was once a grand library. Broken shelves line the walls, and scattered parchments lie across the floor. A few intact books rest on a reading table, their pages yellowed with age but still legible."
            
            {6, 6} -> "Armory\nA well-organized armory with weapons and armor displayed on stands and hanging from hooks. Most of the equipment shows signs of age, but some pieces still gleam with careful maintenance. A forge in the corner appears recently used."
            
            {7, 7} -> "Crystal Cavern\nA natural cavern where the walls are embedded with glowing crystals that provide a soft, blue-white light. The crystals hum with a barely audible resonance, and the air shimmers with magical energy."
            
            {8, 8} -> "Underground Lake\nYou stand on the shore of a vast underground lake. The water is crystal clear and so still it perfectly reflects the cavern ceiling above. Strange fish with luminescent scales can be seen swimming in the depths."
            
            {9, 9} -> "Ancient Shrine\nA small shrine dedicated to forgotten deities. Stone statues stand in alcoves around the room, their faces worn smooth by time. An altar in the center holds offerings left by previous visitors - coins, flowers, and small trinkets."
            
            _ -> 
              # Check tile type for other positions
              if y >= 0 and y < length(game_state.map_data) do
                row = Enum.at(game_state.map_data, y)
                if x >= 0 and x < length(row) do
                  tile = Enum.at(row, x)
                  case tile do
                    0 -> "Solid Stone Wall\nYou face an impenetrable wall of fitted stone blocks. The craftsmanship is excellent, with no gaps or weaknesses visible. There's no passage here."
                    1 -> "Stone Corridor\nYou are in a well-constructed stone corridor. The walls are made of carefully fitted blocks, and the floor is worn smooth by the passage of many feet over the years. Torch brackets line the walls, though most are empty. The air is cool and carries the faint scent of old stone and distant moisture."
                    2 -> "Underground Pool\nYou stand beside a clear underground pool fed by a natural spring. The water is deep and perfectly still, reflecting the ceiling above like a mirror. Small ripples occasionally disturb the surface as drops fall from stalactites overhead. The air here is humid and fresh."
                    3 -> "Treasure Alcove\nA small alcove has been carved into the stone wall here. The niche shows signs of having once held something valuable - there are mounting brackets and a small pedestal. Scratches on the floor suggest heavy objects were once moved in and out of this space."
                    _ -> "Mystical Chamber\nYou are in a chamber that defies easy description. The very air seems to shimmer with arcane energy, and the walls appear to shift slightly when you're not looking directly at them. Strange symbols carved into the stone pulse with a faint, otherworldly light."
                  end
                else
                  "The Void\nYou have somehow moved beyond the boundaries of the known world. Reality becomes uncertain here, and the very ground beneath your feet feels insubstantial. Wisps of strange energy drift through the air, and distant sounds echo from nowhere."
                end
              else
                "The Void\nYou have somehow moved beyond the boundaries of the known world. Reality becomes uncertain here, and the very ground beneath your feet feels insubstantial. Wisps of strange energy drift through the air, and distant sounds echo from nowhere."
              end
          end
        else
          # For non-tutorial maps, use room data from database if available
          case room do
            nil -> "Empty Space\nYou are in an empty area with no defined room. The ground beneath your feet feels uncertain, as if this space exists between the cracks of reality."
            room -> 
              room_title = room.name || "Unnamed Room"
              room_desc = room.description || "A mysterious room with no particular features. The walls are bare stone, and the air is still and quiet."
              "#{room_title}\n#{room_desc}"
          end
        end
        
        # Check for NPCs at current location
        npcs_here = get_npcs_at_location(x, y, game_state.map_id)
        
        description_lines = [room_description]
        
        # Add NPC descriptions if any are present
        if length(npcs_here) > 0 do
          description_lines = description_lines ++ [""]  # Empty line for spacing
          
          # Add each NPC with their description
          npc_descriptions = Enum.map(npcs_here, fn npc ->
            npc_name = Map.get(npc, :name) || "Unknown NPC"
            npc_desc = Map.get(npc, :description) || "They look at you with interest."
            "#{npc_name} is here.\n#{npc_desc}"
          end)
          description_lines = description_lines ++ npc_descriptions
        end
        
        # Add available exits information
        exits = get_available_exits(x, y, room)
        if length(exits) > 0 do
          description_lines = description_lines ++ [""]
          exit_text = "Exits: " <> Enum.join(exits, ", ")
          description_lines = description_lines ++ [exit_text]
        else
          description_lines = description_lines ++ ["", "There are no obvious exits."]
        end
        
        {description_lines, game_state}

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

      "npc" ->
        {x, y} = game_state.player_position
        npcs_here = get_npcs_at_location(x, y, game_state.map_id)
        
        if length(npcs_here) > 0 do
          response = ["NPCs in this area:"] ++
            Enum.flat_map(npcs_here, fn npc ->
              npc_name = Map.get(npc, :name) || "Unknown NPC"
              npc_desc = Map.get(npc, :description) || "They look at you with interest."
              ["", "#{npc_name}:", npc_desc]
            end)
          {response, game_state}
        else
          {["There are no NPCs in this area."], game_state}
        end

      cmd when cmd in ["north", "n"] ->
        execute_movement(game_state, "ArrowUp")

      cmd when cmd in ["south", "s"] ->
        execute_movement(game_state, "ArrowDown")

      cmd when cmd in ["east", "e"] ->
        execute_movement(game_state, "ArrowRight")

      cmd when cmd in ["west", "w"] ->
        execute_movement(game_state, "ArrowLeft")

      cmd when cmd in ["northeast", "ne"] ->
        execute_movement(game_state, "northeast")

      cmd when cmd in ["southeast", "se"] ->
        execute_movement(game_state, "southeast")

      cmd when cmd in ["northwest", "nw"] ->
        execute_movement(game_state, "northwest")

      cmd when cmd in ["southwest", "sw"] ->
        execute_movement(game_state, "southwest")

      _ ->
        # Check if it's a talk command
        case parse_talk_command(command) do
          {:ok, npc_name} ->
            execute_talk_command(game_state, npc_name)
          :error ->
            {["Unknown command: '#{command}'. Type 'help' for available commands."], game_state}
        end
    end
  end

  # Execute movement command and update game state
  defp execute_movement(game_state, direction) do
    current_pos = game_state.player_position
    new_pos = calc_position(current_pos, direction, game_state.map_data)

    if new_pos == current_pos do
      response = ["You cannot move in that direction. There's no room or passage that way."]
      {response, game_state}
    else
      direction_name = case direction do
        "ArrowUp" -> "north"
        "ArrowDown" -> "south"
        "ArrowRight" -> "east"
        "ArrowLeft" -> "west"
        "northeast" -> "northeast"
        "southeast" -> "southeast"
        "northwest" -> "northwest"
        "southwest" -> "southwest"
      end

      # Update game state with new position
      updated_game_state = %{game_state | player_position: new_pos}
      
      # Check for NPCs at the new location
      {new_x, new_y} = new_pos
      npcs_here = get_npcs_at_location(new_x, new_y, game_state.map_id)
      
      response = ["You traversed #{direction_name}."]
      
      # Add NPC presence notification if any NPCs are at the new location
      if length(npcs_here) > 0 do
        npc_names = Enum.map(npcs_here, & &1.name) |> Enum.join(", ")
        response = response ++ ["You see #{npc_names} here."]
      end

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

  # Helper function to get available exits from current position
  defp get_available_exits(x, y, room) do
    exits = []
    
    # If we have a room, check for doors
    exits = if room do
      # Get doors from this room using Ecto query since the function might not exist
      doors = from(d in GameMap.Door, where: d.from_room_id == ^room.id)
              |> Repo.all()
      door_exits = Enum.map(doors, fn door ->
        cond do
          door.door_type == "secret" and door.is_locked -> nil  # Hidden secret doors
          door.is_locked -> "#{door.direction} (locked)"
          door.key_required && door.key_required != "" -> "#{door.direction} (key required)"
          true -> door.direction
        end
      end)
      |> Enum.filter(& &1 != nil)
      
      exits ++ door_exits
    else
      exits
    end
    
    # For tutorial terrain, also check basic movement possibilities
    basic_directions = ["north", "south", "east", "west", "northeast", "southeast", "northwest", "southwest"]
    
    tutorial_exits = Enum.filter(basic_directions, fn direction ->
      test_pos = calc_position({x, y}, direction_to_key(direction), nil)
      test_pos != {x, y} and is_valid_movement?({x, y}, test_pos, direction_to_key(direction))
    end)
    
    (exits ++ tutorial_exits)
    |> Enum.uniq()
    |> Enum.sort()
  end
  
  # Helper function to convert direction string to key for calc_position
  defp direction_to_key(direction) do
    case direction do
      "north" -> "ArrowUp"
      "south" -> "ArrowDown"
      "east" -> "ArrowRight"
      "west" -> "ArrowLeft"
      "northeast" -> "northeast"
      "southeast" -> "southeast"
      "northwest" -> "northwest"
      "southwest" -> "southwest"
      _ -> direction
    end
  end

  # Parse talk command to extract NPC name
  defp parse_talk_command(command) do
    # Match patterns like: talk "npc name", talk 'npc name', talk npc_name
    cond do
      # Match talk "npc name" or talk 'npc name'
      Regex.match?(~r/^talk\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^talk\s+["'](.+)["']\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end
      
      # Match talk npc_name (single word, no quotes)
      Regex.match?(~r/^talk\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^talk\s+(\w+)\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end
      
      true -> :error
    end
  end

  # Execute talk command with a specific NPC
  defp execute_talk_command(game_state, npc_name) do
    {x, y} = game_state.player_position
    npcs_here = get_npcs_at_location(x, y, game_state.map_id)
    
    # Find the NPC by name (case-insensitive)
    target_npc = Enum.find(npcs_here, fn npc ->
      npc_name_normalized = String.downcase(npc.name || "")
      input_name_normalized = String.downcase(npc_name)
      npc_name_normalized == input_name_normalized
    end)
    
    case target_npc do
      nil ->
        if length(npcs_here) > 0 do
          available_names = Enum.map(npcs_here, & &1.name) |> Enum.join(", ")
          response = [
            "There is no NPC named '#{npc_name}' here.",
            "Available NPCs: #{available_names}"
          ]
          {response, game_state}
        else
          {["There are no NPCs here to talk to."], game_state}
        end
      
      npc ->
        # Generate dialogue based on NPC
        dialogue_response = generate_npc_dialogue(npc, game_state)
        {dialogue_response, game_state}
    end
  end

  # Generate dialogue for an NPC
  defp generate_npc_dialogue(npc, game_state) do
    npc_name = npc.name || "Unknown NPC"
    
    # Special dialogue for Goldie in tutorial
    if npc_name == "Goldie" and game_state.map_id == "tutorial_terrain" do
      [
        "#{npc_name} wags her tail enthusiastically as you approach.",
        "",
        "Goldie says: \"Woof! Welcome to Shard, adventurer! I'm here to help you learn the basics.\"",
        "",
        "\"Try using these commands to get started:\"",
        "  • 'look' - to examine your surroundings",
        "  • 'north', 'south', 'east', 'west' - to move around",
        "  • 'stats' - to check your character information",
        "  • 'npc' - to see who's around you",
        "",
        "\"There's treasure to the southeast if you're feeling adventurous!\"",
        "\"Remember, you can always type 'help' if you get stuck.\"",
        "",
        "Goldie sits and tilts her head, waiting to see what you'll do next."
      ]
    else
      # Default dialogue for other NPCs
      dialogue = case npc.dialogue do
        nil -> "#{npc_name} looks at you but doesn't seem to have much to say."
        "" -> "#{npc_name} nods at you in acknowledgment."
        dialogue_text -> dialogue_text
      end
      
      # Add some personality based on NPC type
      personality_response = case npc.npc_type do
        "friendly" -> "#{npc_name} smiles warmly at you."
        "hostile" -> "#{npc_name} glares at you menacingly."
        "neutral" -> "#{npc_name} regards you with mild interest."
        "merchant" -> "#{npc_name} eyes you as a potential customer."
        "guard" -> "#{npc_name} stands at attention and nods formally."
        _ -> "#{npc_name} acknowledges your presence."
      end
      
      [
        personality_response,
        "",
        "#{npc_name} says: \"#{dialogue}\"",
        "",
        "#{npc_name} waits to see if you have anything else to say."
      ]
    end
  end

  # Helper function to get NPCs at a specific location
  defp get_npcs_at_location(x, y, map_id) do
    # For tutorial terrain, handle special NPCs
    cond do
      map_id == "tutorial_terrain" and x == 0 and y == 0 ->
        # Always return Goldie at (0,0) for tutorial terrain
        goldie = %{
          name: "Goldie",
          description: "A friendly golden retriever with bright, intelligent eyes and a constantly wagging tail. Her golden fur gleams in the torchlight, and she sits patiently beside the entrance, as if she's been waiting for you. She wears a small leather collar with a brass nameplate that reads 'Goldie - Tutorial Guide'. Her demeanor is warm and welcoming, and she seems eager to help newcomers learn the ways of this mysterious world.",
          location_x: 0,
          location_y: 0,
          location_z: 0,
          health: 100,
          max_health: 100,
          mana: 50,
          max_mana: 50,
          level: 1,
          experience_reward: 0,
          is_active: true,
          npc_type: "friendly"
        }
        [goldie]
      
      map_id == "tutorial_terrain" and x == 0 and y == 1 ->
        # Elder wizard at (0,1) for tutorial terrain
        elder_wizard = %{
          name: "Elder Wizard",
          description: "An ancient wizard with a long, flowing white beard that reaches nearly to the floor. His weathered face is lined with countless years of wisdom, and his piercing blue eyes seem to see through time itself. He wears deep purple robes adorned with silver stars and moons that shimmer with their own inner light. A gnarled oak staff topped with a glowing crystal rests in his right hand, pulsing gently with arcane energy. Despite his advanced age, he stands tall and proud, radiating an aura of immense magical power and knowledge.",
          location_x: 0,
          location_y: 1,
          location_z: 0,
          health: 1000,
          max_health: 1000,
          mana: 500,
          max_mana: 500,
          level: 50,
          experience_reward: 0,
          is_active: true,
          npc_type: "neutral",
          dialogue: "The ancient throne pulses with magical energy. You hear a deep, resonant voice echo in your mind: 'Welcome, young adventurer. I have watched over this realm for millennia. Seek knowledge, grow strong, and remember that true power comes from wisdom, not force.'"
        }
        [elder_wizard]
      
      true ->
        # For other locations and maps, check database
        import Ecto.Query
        npcs = from(n in Npc,
          where: n.location_x == ^x and n.location_y == ^y and n.is_active == true)
        |> Repo.all()
        npcs
    end
  end

  # Helper function to generate map data from database
  defp generate_map_from_database(map_id \\ "tutorial_terrain") do
    # For tutorial terrain, always return the same predefined map
    if map_id == "tutorial_terrain" do
      generate_default_map(map_id)
    else
      # Get all rooms from database for other map types
      rooms = Repo.all(GameMap.Room)
      
      # If no rooms exist, return a map based on the selected map_id
      if Enum.empty?(rooms) do
        generate_default_map(map_id)
      else
        # Find the bounds of all rooms
        {min_x, max_x} = rooms 
          |> Enum.map(& &1.x_coordinate) 
          |> Enum.filter(& &1 != nil)
          |> case do
            [] -> {0, 10}
            coords -> Enum.min_max(coords)
          end
        
        {min_y, max_y} = rooms 
          |> Enum.map(& &1.y_coordinate) 
          |> Enum.filter(& &1 != nil)
          |> case do
            [] -> {0, 10}
            coords -> Enum.min_max(coords)
          end
        
        # Add padding around the map
        min_x = min_x - 1
        max_x = max_x + 1
        min_y = min_y - 1
        max_y = max_y + 1
        
        # Create a map of room coordinates for quick lookup
        room_map = rooms
          |> Enum.filter(fn room -> room.x_coordinate != nil and room.y_coordinate != nil end)
          |> Enum.into(%{}, fn room -> {{room.x_coordinate, room.y_coordinate}, room} end)
        
        # Generate the grid
        for y <- min_y..max_y do
          for x <- min_x..max_x do
            case room_map[{x, y}] do
              nil -> 0  # Wall/empty space
              room -> 
                case room.room_type do
                  "treasure" -> 3  # Treasure room
                  "water" -> 2     # Water room
                  _ -> 1           # Regular floor
                end
            end
          end
        end
      end
    end
  end
  
  # Fallback function for when no rooms exist in database
  defp generate_default_map(map_id \\ "tutorial_terrain") do
    case map_id do
      "tutorial_terrain" ->
        # Generate a simple tutorial map
        for y <- 0..10 do
          for x <- 0..10 do
            cond do
              x == 0 and y == 0 -> 1  # Starting position where Goldie is - must be floor
              x == 0 or y == 0 or x == 10 or y == 10 -> 0  # Walls around the edges (except starting position)
              x == 5 and y == 5 -> 3  # Treasure in the center
              x > 3 and x < 7 and y > 3 and y < 7 -> 1  # Central room floor
              rem(x + y, 4) == 0 -> 1  # Scattered floor tiles for tutorial
              true -> 0  # Walls for tutorial simplicity
            end
          end
        end
      _ ->
        # Default fallback map for any other map_id
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
  
  # Find a valid starting position on the map (first non-wall tile)
  defp find_valid_starting_position(_map_data) do
    # For tutorial terrain, always start at {0,0} where Goldie is
    {0, 0}
  end

  # Calculate bounds and scale factor for minimap rendering
  defp calculate_minimap_bounds(rooms) do
    if Enum.empty?(rooms) do
      # Default bounds if no rooms - center around origin
      {{-5, -5, 5, 5}, 15.0}
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
      
      # Calculate scale to fit in 300x200 minimap with padding
      width = max_x - min_x
      height = max_y - min_y
      
      # Ensure minimum size to prevent division by zero
      width = max(width, 1)
      height = max(height, 1)
      
      scale_x = 260 / width  # 260 to leave 20px padding on each side
      scale_y = 160 / height  # 160 to leave 20px padding top/bottom
      scale_factor = min(scale_x, scale_y)
      
      # Ensure minimum scale factor for visibility
      scale_factor = max(scale_factor, 5.0)
      
      {{min_x, min_y, max_x, max_y}, scale_factor}
    end
  end

  # Calculate position within minimap coordinates
  defp calculate_minimap_position({x, y}, {min_x, min_y, _max_x, _max_y}, scale_factor) do
    # Translate to origin and scale, then center in minimap
    scaled_x = (x - min_x) * scale_factor + 20  # 20px padding
    scaled_y = (y - min_y) * scale_factor + 20  # 20px padding
    
    # Ensure coordinates are within bounds
    scaled_x = max(10, min(scaled_x, 290))
    scaled_y = max(10, min(scaled_y, 190))
    
    {scaled_x, scaled_y}
  end

  # Check if a door is one-way (no return door in opposite direction)
  defp is_one_way_door?(door) do
    opposite_direction = get_opposite_direction(door.direction)
    
    if opposite_direction do
      # Check if there's a door going back from the destination room
      return_door = GameMap.get_door_in_direction(door.to_room_id, opposite_direction)
      
      case return_door do
        nil -> true  # No return door found, this is one-way
        return_door -> return_door.to_room_id != door.from_room_id  # Return door doesn't lead back
      end
    else
      false  # Can't determine opposite direction, assume two-way
    end
  end

  # Get the opposite direction for checking return doors
  defp get_opposite_direction(direction) do
    case direction do
      "north" -> "south"
      "south" -> "north"
      "east" -> "west"
      "west" -> "east"
      "northeast" -> "southwest"
      "southwest" -> "northeast"
      "northwest" -> "southeast"
      "southeast" -> "northwest"
      "up" -> "down"
      "down" -> "up"
      _ -> nil
    end
  end

  # Component for player marker when no room exists at player position
  def player_marker(assigns) do
    {x_pos, y_pos} = calculate_minimap_position(
      assigns.position, 
      assigns.bounds, 
      assigns.scale_factor
    )
    
    assigns = assign(assigns, x_pos: x_pos, y_pos: y_pos)
    
    ~H"""
    <circle 
      cx={@x_pos} 
      cy={@y_pos} 
      r="8" 
      fill="#ef4444" 
      stroke="#ffffff" 
      stroke-width="2"
      opacity="0.9"
    >
      <title>Player at <%= format_position(@position) %> (no room)</title>
    </circle>
    """
  end

  # Component for individual map cells (legacy grid-based map)
  def map_cell_legacy(assigns) do
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
    <div class={"w-6 h-6 #{@color_class} #{@player_class} border border-gray-800"}>
    </div>
    """
  end
end
