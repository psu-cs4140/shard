# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule ShardWeb.MudGameLive do
  @moduledoc false
  use ShardWeb, :live_view

  alias Phoenix.LiveView.JS
  import ShardWeb.UserLive.Components
  import ShardWeb.UserLive.Components2
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.MapComponents
  import ShardWeb.UserLive.LegacyMap
  import ShardWeb.UserLive.MonsterComponents
  import ShardWeb.UserLive.CharacterHelpers
  import ShardWeb.UserLive.ItemHelpers
  import ShardWeb.UserLive.MudGameHandlers
  import ShardWeb.UserLive.MudGameLive2
  # import ShardWeb.UserLive.MudGameHelpers

  # Chat component
  defp chat(assigns) do
    ~H"""
    <div class="flex flex-col h-full min-h-0">
      <!-- Chat Messages -->
      <div
        class="flex-1 bg-black p-4 font-mono text-sm overflow-y-auto border border-gray-600 rounded min-h-0"
        id="chat-messages"
        phx-hook="ChatScroll"
      >
        <div class="whitespace-pre-wrap">
          <%= for message <- @chat_state.messages do %>
            <div class="text-blue-400 leading-tight">{message}</div>
          <% end %>
        </div>
      </div>
      
    <!-- Chat Input -->
      <form phx-submit="submit_chat" class="mt-4 flex-shrink-0">
        <div class="flex">
          <input
            type="text"
            name="chat[text]"
            value={@chat_state.current_message}
            phx-change="update_chat"
            placeholder="Type your message..."
            class="flex-1 px-3 py-2 bg-gray-800 border border-gray-600 rounded-l text-white placeholder-gray-400 focus:outline-none focus:border-blue-500"
            autocomplete="off"
          />
          <button
            type="submit"
            class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-r transition-colors"
          >
            Send
          </button>
        </div>
      </form>
    </div>
    """
  end

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity, Credo.Check.Refactor.Nesting
  def mount(%{"map_id" => map_id} = params, _session, socket) do
    with {:ok, character} <- get_character_from_params(params),
         character_name <- get_character_name(params, character),
         {:ok, character} <- load_character_with_associations(character),
         :ok <- setup_tutorial_content(map_id),
         {:ok, socket} <- initialize_game_state(socket, character, map_id, character_name) do
      {:ok, socket}
    else
      {:error, :no_character} ->
        {:ok,
         socket
         |> put_flash(:error, "Please select a character to play")
         |> push_navigate(to: ~p"/maps")}
    end
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div
      class="flex flex-col h-screen bg-gray-900 text-white overflow-hidden"
      phx-window-keydown="keypress"
    >
      <!-- "phx-window-keydown="keypress" -->
      <!-- Header -->
      <header class="bg-gray-800 p-4 shadow-lg flex justify-between items-center">
        <h1 class="text-2xl font-bold">MUD Game</h1>
        <div class="text-right">
          <div class="text-lg font-semibold text-green-400">
            {@character_name}
          </div>
          <div class="text-sm text-gray-400">
            Level {@game_state.player_stats.level}
          </div>
        </div>
      </header>
      
    <!-- Main Content -->
      <div class="flex flex-1 overflow-hidden">
        <!-- Left Panel - Terminal/Chat -->
        <div class="flex-1 p-4 flex flex-col min-h-0">
          <!-- Tab Navigation -->
          <div class="flex mb-4 border-b border-gray-600 flex-shrink-0">
            <button
              class={[
                "px-4 py-2 font-medium transition-colors",
                if(@active_tab == "terminal",
                  do: "text-blue-400 border-b-2 border-blue-400",
                  else: "text-gray-400 hover:text-white"
                )
              ]}
              phx-click="switch_tab"
              phx-value-tab="terminal"
            >
              Terminal
            </button>
            <button
              class={[
                "px-4 py-2 font-medium transition-colors",
                if(@active_tab == "chat",
                  do: "text-blue-400 border-b-2 border-blue-400",
                  else: "text-gray-400 hover:text-white"
                )
              ]}
              phx-click="switch_tab"
              phx-value-tab="chat"
            >
              Chat
            </button>
          </div>
          
    <!-- Tab Content -->
          <div class="flex-1 flex flex-col min-h-0">
            <.terminal :if={@active_tab == "terminal"} terminal_state={@terminal_state} />
            <.chat :if={@active_tab == "chat"} chat_state={@chat_state} />
          </div>
        </div>
        
    <!-- Right Panel - Controls -->
        <div class="w-100 bg-gray-800 px-4 py-4 flex flex-col space-y-4 overflow-y-auto">
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
            click={JS.push("open_modal")}
            value="character_sheet"
          />

          <.control_button
            text="Inventory"
            icon="hero-shopping-bag"
            click={JS.push("open_modal")}
            value="inventory"
          />

          <.control_button
            text="Quests"
            icon="hero-document-text"
            click={JS.push("open_modal")}
            value="quests"
          />

          <.control_button
            text="Map"
            icon="hero-map"
            click={JS.push("open_modal")}
            value="map"
          />

          <.control_button
            text="Settings"
            icon="hero-cog"
            click={JS.push("open_modal")}
            value="settings"
          />

          <%!-- This is used to show char sheet, inventory, etc --%>
          <.character_sheet
            :if={@modal_state.show && @modal_state.type == "character_sheet"}
            game_state={@game_state}
          />

          <.inventory
            :if={@modal_state.show && @modal_state.type == "inventory"}
            game_state={@game_state}
          />

          <.quests :if={@modal_state.show && @modal_state.type == "quests"} game_state={@game_state} />

          <.map
            :if={@modal_state.show && @modal_state.type == "map"}
            game_state={@game_state}
            available_exits={@available_exits}
          />

          <.settings
            :if={@modal_state.show && @modal_state.type == "settings"}
            game_state={@game_state}
          />

          <.dungeon_completion
            :if={@modal_state.show && @modal_state.type == "dungeon_completion"}
            message={@modal_state.completion_message}
          />
        </div>
      </div>
      
    <!-- Footer -->
      <footer class="bg-gray-800 p-2 text-center text-sm">
        <p>MUD Game v1.0</p>
      </footer>
    </div>

    <script>
      window.addEventListener("phx:scroll_to_bottom", (e) => {
        const element = document.getElementById(e.detail.target);
        if (element) {
          element.scrollTop = element.scrollHeight;
        }
      });

      // LiveView hooks
      window.Hooks = window.Hooks || {};

      window.Hooks.ChatScroll = {
        mounted() {
          this.scrollToBottom();
        },
        updated() {
          this.scrollToBottom();
        },
        scrollToBottom() {
          this.el.scrollTop = this.el.scrollHeight;
        }
      };
    </script>
    """
  end

  @impl true
  def handle_event("open_modal", %{"modal" => modal_type}, socket) do
    {:noreply, assign(socket, modal_state: %{show: true, type: modal_type})}
  end

  def handle_event("hide_modal", _params, socket) do
    {:noreply, assign(socket, modal_state: %{show: false, type: "", completion_message: nil})}
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  # Handle keypresses for navigation, inventory, etc.
  def handle_event("keypress", params, socket) do
    case handle_keypress(params, socket) do
      {:noreply, socket, updated_game_state, terminal_state, modal_state, player_position} ->
        {:noreply,
         assign(socket,
           game_state: updated_game_state,
           terminal_state: terminal_state,
           modal_state: modal_state,
           available_exits: compute_available_exits(player_position)
         )}

      result ->
        result
    end
  end

  def handle_event("submit_command", params, socket) do
    case handle_submit_command(params, socket) do
      {:noreply, socket, updated_game_state, terminal_state} ->
        socket = assign(socket, game_state: updated_game_state, terminal_state: terminal_state)

        # Auto-scroll terminal to bottom
        socket = push_event(socket, "scroll_to_bottom", %{target: "terminal-output"})

        {:noreply, socket}

      result ->
        result
    end
  end

  def handle_event("update_command", params, socket) do
    case handle_update_command(params, socket) do
      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_event("submit_chat", %{"chat" => %{"text" => message_text}}, socket) do
    trimmed_message = String.trim(message_text)

    if trimmed_message != "" do
      # Add message to chat
      timestamp =
        DateTime.utc_now() |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 8)

      formatted_message = "[#{timestamp}] #{socket.assigns.character_name}: #{trimmed_message}"

      new_messages = socket.assigns.chat_state.messages ++ [formatted_message]

      chat_state = %{
        messages: new_messages,
        current_message: ""
      }

      socket = assign(socket, chat_state: chat_state)

      # Auto-scroll chat to bottom
      socket = push_event(socket, "scroll_to_bottom", %{target: "chat-messages"})

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_chat", %{"chat" => %{"text" => message_text}}, socket) do
    chat_state = Map.put(socket.assigns.chat_state, :current_message, message_text)
    {:noreply, assign(socket, chat_state: chat_state)}
  end

  def handle_event("save_character_stats", _params, socket) do
    # Manually save character stats to database
    case save_character_stats(
           socket.assigns.game_state.character,
           socket.assigns.game_state.player_stats
         ) do
      {:ok, _character} ->
        terminal_state =
          ShardWeb.UserLive.MudGameHelpers.add_message(
            socket.assigns.terminal_state,
            "Character stats saved successfully."
          )

        socket = assign(socket, :terminal_state, terminal_state)
        {:noreply, socket}

      {:error, _error} ->
        terminal_state =
          ShardWeb.UserLive.MudGameHelpers.add_message(
            socket.assigns.terminal_state,
            "Failed to save character stats."
          )

        socket = assign(socket, :terminal_state, terminal_state)
        {:noreply, socket}
    end
  end

  def handle_event("use_hotbar_item", params, socket) do
    case handle_use_hotbar_item(params, socket) do
      {:noreply, socket, updated_game_state, terminal_state} ->
        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_event("equip_item", params, socket) do
    case handle_equip_item(params, socket) do
      {:noreply, socket, updated_game_state, terminal_state} ->
        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  # (C) Handle clicking an exit button to move rooms
  @impl true
  def handle_event("click_exit", params, socket) do
    case handle_click_exit(params, socket) do
      {:noreply, socket, game_state, terminal_state, player_position} ->
        {:noreply,
         assign(socket,
           game_state: game_state,
           terminal_state: terminal_state,
           available_exits: compute_available_exits(player_position)
         )}

      result ->
        result
    end
  end

  defp get_character_from_params(params) do
    case Map.get(params, "character_id") do
      nil ->
        {:error, :no_character}

      character_id ->
        try do
          character = Shard.Characters.get_character!(character_id)
          {:ok, character}
        rescue
          _ -> {:error, :no_character}
        end
    end
  end

  defp get_character_name(params, character) do
    case Map.get(params, "character_name") do
      nil -> if character, do: character.name, else: "Unknown"
      name -> URI.decode(name)
    end
  end

  defp load_character_with_associations(character) do
    try do
      loaded_character =
        Shard.Repo.get!(Shard.Characters.Character, character.id)
        |> Shard.Repo.preload([:character_inventories, :hotbar_slots])

      {:ok, loaded_character}
    rescue
      _ -> {:ok, character}
    end
  end

  defp setup_tutorial_content("tutorial_terrain") do
    setup_tutorial_key()
    setup_tutorial_npc()
    setup_tutorial_door()
    :ok
  end

  defp setup_tutorial_content(_map_id), do: :ok

  defp setup_tutorial_key do
    case Shard.Items.create_tutorial_key() do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
      _other -> :error
    end
  end

  defp setup_tutorial_npc do
    case Shard.Npcs.create_tutorial_npc_goldie() do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
      _other -> :error
    end
  end

  defp setup_tutorial_door do
    case Shard.Items.create_dungeon_door() do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
    end
  end

  defp initialize_game_state(socket, character, map_id, character_name) do
    map_data = generate_map_from_database(map_id)
    starting_position = find_valid_starting_position(map_data)

    game_state = build_game_state(character, map_data, map_id, starting_position)
    terminal_state = build_terminal_state(starting_position, map_id)
    modal_state = build_modal_state()

    PubSub.subscribe(Shard.PubSub, posn_to_room_channel(game_state.player_position))

    socket =
      assign(socket,
        game_state: game_state,
        terminal_state: terminal_state,
        modal_state: modal_state,
        available_exits: compute_available_exits(game_state.player_position),
        character_name: character_name
      )

    {:ok, socket}
  end

  defp build_game_state(character, map_data, map_id, starting_position) do
    constitution = character.constitution || 10
    base_health = 100
    base_stamina = 100
    base_mana = 50

    max_health = base_health + (constitution - 10) * 5
    max_stamina = base_stamina + (character.dexterity || 10) * 2
    max_mana = base_mana + (character.intelligence || 10) * 3

    %{
      player_position: starting_position,
      map_data: map_data,
      map_id: map_id,
      character: character,
      active_panel: nil,
      player_stats: %{
        health: character.health || max_health,
        max_health: max_health,
        stamina: max_stamina,
        max_stamina: max_stamina,
        mana: character.mana || max_mana,
        max_mana: max_mana,
        level: character.level || 1,
        experience: character.experience || 0,
        next_level_exp: calculate_next_level_exp(character.level || 1),
        strength: character.strength || 10,
        dexterity: character.dexterity || 10,
        intelligence: character.intelligence || 10,
        constitution: constitution
      },
      inventory_items: load_character_inventory(character),
      equipped_weapon: load_equipped_weapon(character),
      hotbar: load_character_hotbar(character),
      quests: [],
      pending_quest_offer: nil,
      monsters: load_monsters_from_database(map_id, starting_position),
      combat: false
    }
  end

  defp build_terminal_state(starting_position, map_id) do
    initial_output = [
      "Welcome to Shard!",
      "You find yourself in a mysterious dungeon.",
      "Type 'help' for available commands.",
      ""
    ]

    terminal_output =
      if starting_position == {0, 0} and map_id == "tutorial_terrain" do
        goldie_dialogue = get_goldie_dialogue()

        initial_output ++
          ["Goldie the golden retriever wags her tail and speaks:", goldie_dialogue, ""]
      else
        initial_output
      end

    %{
      output: terminal_output,
      command_history: [],
      current_command: ""
    }
  end

  defp build_modal_state do
    %{
      show: false,
      type: 0,
      completion_message: nil
    }
  end

  defp get_goldie_dialogue do
    "Woof! Welcome to the tutorial, adventurer!\n\nI'm Goldie, your faithful guide dog. Let me help you get started on your journey.\n\nHere are some basic commands to get you moving:\n• Type 'look' to examine your surroundings\n• Use 'north', 'south', 'east', 'west' (or n/s/e/w) to move around\n• Try 'pickup \"item_name\"' to collect items you find\n• Use 'inventory' to see what you're carrying\n• Type 'help' anytime for a full list of commands\n\nThere's a key hidden somewhere to the south that might come in handy later!\nExplore around and interact with npcs, complete quests, and attack monsters.\nWhen you're ready to move to the next dungeon, unlock the locked door!\nGood luck, and remember - I'll always be here at (0,0) if you need guidance!"
  end

  defp add_message(socket, message) do
    new_output = socket.assigns.terminal_state.output ++ [message] ++ [""]
    ts1 = Map.put(socket.assigns.terminal_state, :output, new_output)
    assign(socket, :terminal_state, ts1)
  end

  @impl true
  def handle_info({:noise, text}, socket) do
    case handle_noise_info({:noise, text}, socket) do
      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_info({:area_heal, xx, msg}, socket) do
    case handle_area_heal_info({:area_heal, xx, msg}, socket) do
      {:noreply, socket, updated_game_state, terminal_state} ->
        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}

      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_info({:update_game_state, new_game_state}, socket) do
    case handle_update_game_state_info({:update_game_state, new_game_state}, socket) do
      {:noreply, socket, game_state} ->
        {:noreply, assign(socket, game_state: game_state)}

      result ->
        result
    end
  end

  def handle_info({:combat_event, event}, socket) do
    case handle_combat_event_info({:combat_event, event}, socket) do
      {:noreply, socket, updated_game_state, terminal_state} ->
        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}

      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_info({:player_joined_combat, player_name}, socket) do
    case handle_player_joined_combat_info({:player_joined_combat, player_name}, socket) do
      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_info({:player_left_combat, player_name}, socket) do
    case handle_player_left_combat_info({:player_left_combat, player_name}, socket) do
      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_info({:combat_action, event}, socket) do
    case handle_combat_action_info({:combat_action, event}, socket) do
      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end
end
