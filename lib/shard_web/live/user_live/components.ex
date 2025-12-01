defmodule ShardWeb.UserLive.Components do
  use ShardWeb, :live_view

  def character_sheet(assigns) do
    ~H"""
    <div
      class="fixed inset-0 flex items-center justify-center"
      style="background-color: rgba(0, 0, 0, 0.5);"
    >
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
              <h4 class="text-lg font-semibold mb-3 text-center">Character Info</h4>
              <div class="space-y-2">
                <div class="flex justify-between">
                  <span>Name:</span>
                  <span class="font-mono">{@game_state.character.name}</span>
                </div>
                <div class="flex justify-between">
                  <span>Class:</span>
                  <span class="font-mono capitalize">
                    {@game_state.character.class || "Adventurer"}
                  </span>
                </div>
                <div class="flex justify-between">
                  <span>Race:</span>
                  <span class="font-mono capitalize">{@game_state.character.race || "Human"}</span>
                </div>
                <div class="flex justify-between">
                  <span>Level:</span>
                  <span class="font-mono">{@game_state.player_stats.level}</span>
                </div>
                <div class="flex justify-between">
                  <span>Gold:</span>
                  <span class="font-mono">{@game_state.character.gold || 0}</span>
                </div>
              </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-4">
              <h4 class="text-lg font-semibold mb-3 text-center">Attributes</h4>
              <div class="space-y-2">
                <div class="flex justify-between">
                  <span>Strength:</span>
                  <span class="font-mono">{@game_state.player_stats.strength}</span>
                </div>
                <div class="flex justify-between">
                  <span>Dexterity:</span>
                  <span class="font-mono">{@game_state.player_stats.dexterity}</span>
                </div>
                <div class="flex justify-between">
                  <span>Intelligence:</span>
                  <span class="font-mono">{@game_state.player_stats.intelligence}</span>
                </div>
                <div class="flex justify-between">
                  <span>Constitution:</span>
                  <span class="font-mono">{@game_state.player_stats.constitution}</span>
                </div>
              </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-4">
              <h4 class="text-lg font-semibold mb-3 text-center">Experience</h4>
              <div class="mb-2">
                <div class="flex justify-between text-sm mb-1">
                  <span>EXP</span>
                  <span>
                    {@game_state.player_stats.experience}/{@game_state.player_stats.next_level_exp}
                  </span>
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
                  <div class="text-xl">
                    {@game_state.player_stats.health}/{@game_state.player_stats.max_health}
                  </div>
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
                  <div class="text-xl">
                    {@game_state.player_stats.stamina}/{@game_state.player_stats.max_stamina}
                  </div>
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
                  <div class="text-xl">
                    {@game_state.player_stats.mana}/{@game_state.player_stats.max_mana}
                  </div>
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

  def inventory(assigns) do
    ~H"""
    <div
      class="fixed inset-0 flex items-center justify-center"
      style="background-color: rgba(0, 0, 0, 0.5);"
    >
      <div class="bg-gray-800 rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div class="bg-gray-700 rounded-lg shadow-lg w-full mx-4 p-6" phx-click-away="hide_modal">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-2xl font-bold">Inventory</h3>
            <button phx-click="hide_modal" class="text-gray-400 hover:text-white">
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>

          <%= if Enum.empty?(@game_state.inventory_items || []) do %>
            <div class="text-center text-gray-400 py-8">
              <.icon name="hero-shopping-bag" class="w-16 h-16 mx-auto mb-4 opacity-50" />
              <p class="text-lg">Your inventory is empty</p>
              <p class="text-sm">Explore the world to find items!</p>
            </div>
          <% else %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <%= for item <- (@game_state.inventory_items || []) do %>
                <div class="bg-gray-800 rounded-lg p-4 flex items-center">
                  <div class="mr-4">
                    <%= case get_item_type(item) do %>
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
                      <% "key" -> %>
                        <.icon name="hero-key" class="w-10 h-10 text-yellow-600" />
                      <% _ -> %>
                        <.icon name="hero-cube" class="w-10 h-10 text-gray-400" />
                    <% end %>
                  </div>
                  <div class="flex-1">
                    <div class="flex justify-between items-start">
                      <div class="font-semibold">{get_item_name(item)}</div>
                      <%= if get_item_quantity(item) > 1 do %>
                        <span class="text-sm bg-gray-600 px-2 py-1 rounded">x{get_item_quantity(item)}</span>
                      <% end %>
                    </div>
                    <div class="text-sm text-gray-300 capitalize">{get_item_type(item)}</div>
                    <%= if get_item_damage(item) do %>
                      <div class="text-sm text-red-300">Damage: {get_item_damage(item)}</div>
                    <% end %>
                    <%= if get_item_defense(item) do %>
                      <div class="text-sm text-blue-300">Defense: {get_item_defense(item)}</div>
                    <% end %>
                    <%= if get_item_effect(item) do %>
                      <div class="text-sm text-green-300">Effect: {get_item_effect(item)}</div>
                    <% end %>
                    <%= if get_item_description(item) do %>
                      <div class="text-xs text-gray-400 mt-1">{get_item_description(item)}</div>
                    <% end %>
                    
    <!-- Action buttons -->
                    <div class="flex gap-2 mt-2">
                      <%= if get_item_type(item) in ["weapon", "armor"] do %>
                        <button
                          phx-click="equip_item"
                          phx-value-item_id={get_item_id(item)}
                          class="text-xs bg-blue-600 hover:bg-blue-700 px-2 py-1 rounded transition-colors"
                        >
                          Equip
                        </button>
                      <% end %>
                      <%= if get_item_type(item) in ["consumable", "key"] do %>
                        <button
                          phx-click="use_hotbar_item"
                          phx-value-item_id={get_item_id(item)}
                          class="text-xs bg-green-600 hover:bg-green-700 px-2 py-1 rounded transition-colors"
                        >
                          Use
                        </button>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def quests(assigns) do
    ~H"""
    <div
      class="fixed inset-0 flex items-center justify-center"
      style="background-color: rgba(0, 0, 0, 0.5);"
    >
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
                  <h4 class="text-lg font-semibold">{quest.title}</h4>
                  <span class={"px-2 py-1 rounded text-xs font-semibold " <>
                    case quest.status do
                      "Completed" -> "bg-green-500"
                      "In Progress" -> "bg-yellow-500"
                      "Available" -> "bg-blue-500"
                    end}>
                    {quest.status}
                  </span>
                </div>
                <div class="mt-2">
                  <div class="flex justify-between text-sm mb-1">
                    <span>Progress</span>
                    <span>{quest.progress}</span>
                  </div>
                  <%= if quest.status != "Completed" do %>
                    <div class="w-full bg-gray-600 rounded-full h-2">
                      <% progress_percent =
                        case quest.status do
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

  def settings(assigns) do
    ~H"""
    <div
      class="fixed inset-0 flex items-center justify-center"
      style="background-color: rgba(0, 0, 0, 0.5);"
    >
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
                    <input type="checkbox" class="sr-only peer" />
                    <div class="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600">
                    </div>
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
                  <input type="range" min="0" max="100" value="80" class="w-32" />
                </div>
                <div class="flex items-center justify-between">
                  <span>Music Volume</span>
                  <input type="range" min="0" max="100" value="70" class="w-32" />
                </div>
                <div class="flex items-center justify-between">
                  <span>Sound Effects</span>
                  <input type="range" min="0" max="100" value="90" class="w-32" />
                </div>
              </div>
            </div>

            <div class="bg-gray-800 rounded-lg p-4">
              <h4 class="text-lg font-semibold mb-3">Gameplay</h4>
              <div class="space-y-3">
                <div class="flex items-center justify-between">
                  <span>Enable Auto-Save</span>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" class="sr-only peer" checked />
                    <div class="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600">
                    </div>
                  </label>
                </div>
                <div class="flex items-center justify-between">
                  <span>Show Tutorial Tips</span>
                  <label class="relative inline-flex items-center cursor-pointer">
                    <input type="checkbox" class="sr-only peer" checked />
                    <div class="w-11 h-6 bg-gray-600 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-blue-600">
                    </div>
                  </label>
                </div>
              </div>
            </div>

            <div class="flex justify-end">
              <button
                phx-click="hide_modal"
                class="px-4 py-2 bg-blue-600 hover:bg-blue-700 rounded-lg mr-2"
              >
                Save Settings
              </button>
              <button
                phx-click="hide_modal"
                class="px-4 py-2 bg-gray-600 hover:bg-gray-700 rounded-lg"
              >
                Cancel
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper functions to safely extract item data from different structures
  defp get_item_name(item) do
    cond do
      item.item && item.item.name -> item.item.name
      item.name -> item.name
      true -> "Unknown Item"
    end
  end

  defp get_item_quantity(item) do
    item.quantity || 1
  end

  defp get_item_type(item) do
    cond do
      item.item && item.item.item_type -> item.item.item_type
      item.item_type -> item.item_type
      true -> "misc"
    end
  end

  defp get_item_damage(item) do
    Map.get(item.item || item, :damage)
  end

  defp get_item_defense(item) do
    Map.get(item.item || item, :defense)
  end

  defp get_item_effect(item) do
    Map.get(item.item || item, :effect)
  end

  defp get_item_description(item) do
    Map.get(item.item || item, :description)
  end

  defp get_item_id(item) do
    cond do
      item.inventory_id -> item.inventory_id
      item.id -> item.id
      true -> nil
    end
  end
end
