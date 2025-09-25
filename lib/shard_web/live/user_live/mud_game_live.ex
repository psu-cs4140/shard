defmodule ShardWeb.MudGameLive do
  use ShardWeb, :live_view
  alias Shard.Map, as: GameMap
  alias Shard.Npcs.Npc
  alias Shard.Quests.Quest
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
        
      ],
      pending_quest_offer: nil  # Stores quest offer waiting for acceptance/denial
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

    {:ok,
 assign(socket,
   game_state: game_state,
   terminal_state: terminal_state,
   modal_state: modal_state,
   available_exits: compute_available_exits(game_state.player_position)
 )}
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

  # Execute quest acceptance
  defp execute_accept_quest(game_state) do
    case game_state.pending_quest_offer do
      nil ->
        {["There is no quest offer to accept."], game_state}
      
      %{quest: quest, npc: npc} ->
        npc_name = npc.name || "Unknown NPC"
        quest_title = quest.title || "Untitled Quest"
        
        # Check if quest has already been accepted or completed
        user_id = 1  # Mock user_id - should come from session in real implementation
        
        already_accepted = try do
          Shard.Quests.quest_ever_accepted_by_user?(user_id, quest.id)
        rescue
          error ->
            IO.inspect(error, label: "Error checking if quest already accepted")
            false
        end
        
        if already_accepted do
          response = [
            "#{npc_name} looks at you with confusion.",
            "",
            "\"You have already accepted this quest. I cannot offer it to you again.\""
          ]
          
          updated_game_state = %{game_state | pending_quest_offer: nil}
          {response, updated_game_state}
        else
          # Accept the quest in the database
          accept_result = try do
            Shard.Quests.accept_quest(user_id, quest.id)
          rescue
            error ->
            IO.inspect(error, label: "Error accepting quest")
            {:error, :database_error}
          end
          
          case accept_result do
            {:ok, _quest_acceptance} ->
              # Add quest to player's active quests in game state
              new_quest = %{
                id: quest.id,
                title: quest_title,
                status: "In Progress",
                progress: "0% complete",
                npc_giver: npc_name,
                description: quest.description
              }
              
              updated_quests = [new_quest | game_state.quests]
              
              response = [
                "You accept the quest '#{quest_title}' from #{npc_name}.",
                "",
                "#{npc_name} says: \"Excellent! I knew I could count on you.\"",
                "",
                "Quest '#{quest_title}' has been added to your quest log."
              ]
              
              updated_game_state = %{game_state | 
                quests: updated_quests,
                pending_quest_offer: nil
              }
              
              {response, updated_game_state}
            
            {:error, :quest_already_completed} ->
              response = [
                "#{npc_name} looks at you with confusion.",
                "",
                "\"You have already completed this quest. I cannot offer it to you again.\""
              ]
              
              updated_game_state = %{game_state | pending_quest_offer: nil}
              {response, updated_game_state}
            
            {:error, :database_error} ->
              # Fallback: add quest to game state even if database fails
              new_quest = %{
                id: quest.id,
                title: quest_title,
                status: "In Progress",
                progress: "0% complete",
                npc_giver: npc_name,
                description: quest.description
              }
              
              updated_quests = [new_quest | game_state.quests]
              
              response = [
                "You accept the quest '#{quest_title}' from #{npc_name}.",
                "",
                "#{npc_name} says: \"Excellent! I knew I could count on you.\"",
                "",
                "Quest '#{quest_title}' has been added to your quest log.",
                "(Note: Quest saved locally due to database issue)"
              ]
              
              updated_game_state = %{game_state | 
                quests: updated_quests,
                pending_quest_offer: nil
              }
              
              {response, updated_game_state}
            
            {:error, _changeset} ->
              response = [
                "#{npc_name} looks troubled.",
                "",
                "\"I'm sorry, but there seems to be an issue with accepting this quest right now.\""
              ]
              
              updated_game_state = %{game_state | pending_quest_offer: nil}
              {response, updated_game_state}
          end
        end
    end
  end

  # Execute quest denial
  defp execute_deny_quest(game_state) do
    case game_state.pending_quest_offer do
      nil ->
        {["There is no quest offer to deny."], game_state}
      
      %{quest: quest, npc: npc} ->
        npc_name = npc.name || "Unknown NPC"
        quest_title = quest.title || "Untitled Quest"
        
        response = [
          "You decline the quest '#{quest_title}' from #{npc_name}.",
          "",
          "#{npc_name} says: \"I understand. Perhaps another time when you're ready.\"",
          "",
          "The quest offer has been declined."
        ]
        
        updated_game_state = %{game_state | pending_quest_offer: nil}
        
        {response, updated_game_state}
    end
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
                <%= String.capitalize(exit.direction) %>
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