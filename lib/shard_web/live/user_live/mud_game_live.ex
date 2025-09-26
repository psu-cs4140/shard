defmodule ShardWeb.MudGameLive do
  use ShardWeb, :live_view
  alias Shard.Map, as: GameMap
  alias Shard.Repo

  @impl true
  def mount(_params, _session, socket) do
    # Generate map data first
    map_data = generate_map_from_database()

    # Find a valid starting position (first floor tile found)
    starting_position = find_valid_starting_position(map_data)

    # Initialize game state
    game_state = %{
      player_position: starting_position,
      map_data: map_data,
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
      ],

      # Will pull from db once that is created.
      monsters: [
        %{
          monster_id: 1,
          name: "Goblin",
          level: 1,
          attack: 10,
          defense: 0,
          speed: 5,
          xp_reward: 5,
          gold_reward: 2,
          boss: false,
          hp: 30,
          hp_max: 30,
          position: find_valid_monster_position(map_data, starting_position)
        },
        %{
          monster_id: 1,
          name: "Goblin",
          level: 1,
          attack: 10,
          defense: 0,
          speed: 5,
          xp_reward: 5,
          gold_reward: 2,
          boss: false,
          hp: 30,
          hp_max: 30,
          position: find_valid_monster_position(map_data, starting_position)
        },%{
          monster_id: 1,
          name: "Goblin",
          level: 1,
          attack: 10,
          defense: 0,
          speed: 5,
          xp_reward: 5,
          gold_reward: 2,
          boss: false,
          hp: 30,
          hp_max: 30,
          position: find_valid_monster_position(map_data, starting_position)
        }
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
    {response, updated_game_state} = case key do
      "ArrowUp" -> execute_movement(socket.assigns.game_state, "north")
      "ArrowDown" -> execute_movement(socket.assigns.game_state, "south")
      "ArrowRight" -> execute_movement(socket.assigns.game_state, "east")
      "ArrowLeft" -> execute_movement(socket.assigns.game_state, "west")
      _ -> {:noreply, socket}
    end
    {response, updated_game_state}
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
          "  north/south/east/west - Move in cardinal directions",
          "  northeast/southeast/northwest/southwest - Move diagonally",
          "  Shortcuts: n/s/e/w/ne/se/nw/sw",
          "  help - Show this help message"
        ]
        {response, game_state}

      "look" ->
        {x, y} = game_state.player_position
        tile = game_state.map_data |> Enum.at(y) |> Enum.at(x)
        monsters = Enum.filter(game_state.monsters, fn value -> value[:position] == game_state.player_position end)
        monster_count = Enum.count(monsters)
        description = case monster_count do
          0 -> case tile do
            0 -> "You see a solid stone wall."
            1 -> "You are standing on a stone floor. The air is cool and damp."
            2 -> "You see clear blue water. It looks deep."
            3 -> "A glittering treasure chest sits here, beckoning you closer."
            _ -> "You see something strange and unidentifiable."
          end
          1 -> "There is a " <> Enum.at(monsters, 0)[:name] <>"! It attacks you for " <> to_string(Enum.at(monsters, 0)[:attack]) <> " damage."
          _ -> "There are " <> to_string(monster_count) <> " monsters! The monsters include " <> Enum.map_join(monsters, ", ", fn monster -> "a " <> to_string(monster[:name]) end)
        end

        new_game_state = if monster_count > 0 do
          stats = game_state.player_stats
          new_hp = stats.health - Enum.at(monsters, 0)[:attack]
          %{
            player_position: game_state.player_position,
            map_data: game_state.map_data,
            active_panel: game_state.active_panel,
            player_stats: %{
              health: new_hp,
              max_health: game_state.player_stats.max_health,
              stamina: game_state.player_stats.stamina,
              max_stamina: game_state.player_stats.max_stamina,
              mana: game_state.player_stats.mana,
              max_mana: game_state.player_stats.max_mana,
              level: game_state.player_stats.level,
              experience: game_state.player_stats.experience,
              next_level_exp: game_state.player_stats.next_level_exp,
              strength: game_state.player_stats.strength,
              dexterity: game_state.player_stats.dexterity,
              intelligence: game_state.player_stats.intelligence
            },
            inventory_items: game_state.inventory_items,
            hotbar: game_state.hotbar,
            quests: game_state.quests,
            monsters: game_state.monsters,
          }
        else
          game_state
        end

        {[description], new_game_state}

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

      cmd when cmd in ["northeast", "ne"] ->
        execute_movement(game_state, "northeast")

      cmd when cmd in ["southeast", "se"] ->
        execute_movement(game_state, "southeast")

      cmd when cmd in ["northwest", "nw"] ->
        execute_movement(game_state, "northwest")

      cmd when cmd in ["southwest", "sw"] ->
        execute_movement(game_state, "southwest")

      _ ->
        {["Unknown command: '#{command}'. Type 'help' for available commands."], game_state}
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

      monsters = Enum.filter(game_state.monsters, fn value -> value[:position] == new_pos end)
      monster_count = Enum.count(monsters)
      description = case monster_count do
        0 -> "No monsters are present."
        1 -> "There is a " <> Enum.at(monsters, 0)[:name] <>"! It prepares to attack."
        _ -> "There are " <> to_string(monster_count) <> " monsters! The monsters include " <> Enum.map_join(monsters, ", ", fn monster -> "a " <> to_string(monster[:name]) end) <> ". They prepare to attack."
      end

      # "There is a " <> Enum.at(monsters, 0)[:name] <>"! It attacks you for " <> to_string(Enum.at(monsters, 0)[:attack]) <> " damage."
      # "There are " <> to_string(monster_count) <> " monsters! The monsters include " <> Enum.map_join(monsters, ", ", fn monster -> "a " <> to_string(monster[:name]) end)
      # new_game_state = if monster_count > 0 do
      #   stats = game_state.player_stats
      #   new_hp = stats.health - Enum.at(monsters, 0)[:attack]
      #   %{
      #     player_position: new_pos,
      #     map_data: game_state.map_data,
      #     active_panel: game_state.active_panel,
      #     player_stats: %{
      #       health: new_hp,
      #       max_health: game_state.player_stats.max_health,
      #       stamina: game_state.player_stats.stamina,
      #       max_stamina: game_state.player_stats.max_stamina,
      #       mana: game_state.player_stats.mana,
      #       max_mana: game_state.player_stats.max_mana,
      #       level: game_state.player_stats.level,
      #       experience: game_state.player_stats.experience,
      #       next_level_exp: game_state.player_stats.next_level_exp,
      #       strength: game_state.player_stats.strength,
      #       dexterity: game_state.player_stats.dexterity,
      #       intelligence: game_state.player_stats.intelligence
      #     },
      #     inventory_items: game_state.inventory_items,
      #     hotbar: game_state.hotbar,
      #     quests: game_state.quests,
      #     monsters: game_state.monsters,
      #   }
      # else
      #   game_state
      # end

      # Update game state with new position
      updated_game_state = %{game_state | player_position: new_pos}
      response = ["You traversed #{direction_name}.\n" <> description]

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

  # Helper function to generate map data from database
  defp generate_map_from_database() do
    # Get all rooms from database
    rooms = Repo.all(GameMap.Room)

    # If no rooms exist, return a simple default map
    if Enum.empty?(rooms) do
      generate_default_map()
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

  # Fallback function for when no rooms exist in database
  defp generate_default_map() do
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

  # Find a valid starting position on the map (first non-wall tile)
  defp find_valid_starting_position(map_data) do
    # Search for the first floor tile (value 1, 2, or 3 - anything but 0 which is wall)
    Enum.with_index(map_data)
    |> Enum.find_value(fn {row, y} ->
      Enum.with_index(row)
      |> Enum.find_value(fn {cell, x} ->
        if cell != 0, do: {x, y}, else: nil
      end)
    end)
    |> case do
      nil -> {0, 0}  # Fallback if no valid position found (shouldn't happen)
      position -> position
    end
  end

  # Generate a position that is not where the player started
  # Claude helped write this one
  defp find_valid_monster_position(map_data, starting_position) do
    map_data
    |> Enum.with_index()
    |> Enum.flat_map(fn {row, row_index} -> row
      |> Enum.with_index()
      |> Enum.filter(fn {value, _} -> value == 1 end)
      |> Enum.map(fn {_, col_index} -> {row_index, col_index} end)
      |> Enum.filter(fn {row_index, col_index} -> {row_index, col_index} != starting_position end)
      end)
    |> Enum.random()
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
