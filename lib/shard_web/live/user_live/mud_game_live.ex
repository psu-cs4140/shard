# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule ShardWeb.MudGameLive do
  @moduledoc false
  use ShardWeb, :live_view

  alias Phoenix.LiveView.JS
  import ShardWeb.UserLive.Components
  import ShardWeb.UserLive.Components2
  # import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.MapComponents
  # import ShardWeb.UserLive.LegacyMap
  # import ShardWeb.UserLive.MonsterComponents
  import ShardWeb.UserLive.CharacterHelpers
  #  import ShardWeb.UserLive.ItemHelpers
  import ShardWeb.UserLive.MudGameHandlers
  import ShardWeb.UserLive.MudGameLive2
  import ShardWeb.UserLive.Commands3
  # import ShardWeb.UserLive.MudGameHelpers
  import ShardWeb.UserLive.MudGameLiveMultiplayerComponents

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity, Credo.Check.Refactor.Nesting
  def mount(%{"map_id" => map_id} = params, _session, socket) do
    with {:ok, character} <- get_character_from_params(params),
         character_name <- get_character_name(params, character),
         {:ok, character} <- load_character_with_associations(character),
         :ok <- setup_tutorial_content(map_id),
         {:ok, socket} <- initialize_game_state(socket, character, map_id, character_name) do
      # Subscribe to the global chat topic
      Phoenix.PubSub.subscribe(Shard.PubSub, "global_chat")
      # Subscribe to player presence updates
      Phoenix.PubSub.subscribe(Shard.PubSub, "player_presence")

      # Initialize online players list
      socket = assign(socket, online_players: [])

      # Request current online players from existing players
      Phoenix.PubSub.broadcast(
        Shard.PubSub,
        "player_presence",
        {:request_online_players, character.id}
      )

      # Broadcast that this player has joined
      player_data = %{
        name: character_name,
        level: socket.assigns.game_state.player_stats.level,
        character_id: character.id
      }

      Phoenix.PubSub.broadcast(Shard.PubSub, "player_presence", {:player_joined, player_data})

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

          <.online_players online_players={@online_players} />

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
      # Create message data
      timestamp =
        DateTime.utc_now() |> DateTime.to_time() |> Time.to_string() |> String.slice(0, 8)

      message_data = %{
        timestamp: timestamp,
        character_name: socket.assigns.character_name,
        text: trimmed_message
      }

      # Broadcast message to all subscribers
      Phoenix.PubSub.broadcast(Shard.PubSub, "global_chat", {:chat_message, message_data})

      # Clear the input
      chat_state = Map.put(socket.assigns.chat_state, :current_message, "")
      socket = assign(socket, chat_state: chat_state)

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

  def handle_info({:poke_notification, poker_name}, socket) do
    terminal_state = handle_poke_notification(socket.assigns.terminal_state, poker_name)

    # Auto-scroll terminal to bottom
    socket = push_event(socket, "scroll_to_bottom", %{target: "terminal-output"})

    {:noreply, assign(socket, terminal_state: terminal_state)}
  end

  def handle_info({:chat_message, message_data}, socket) do
    # Format the chat message
    formatted_message =
      "[#{message_data.timestamp}] #{message_data.character_name}: #{message_data.text}"

    # Add to chat messages
    chat_state =
      Map.update(socket.assigns.chat_state, :messages, [], fn messages ->
        # Keep only the last 100 messages to prevent memory issues
        (messages ++ [formatted_message]) |> Enum.take(-100)
      end)

    {:noreply, assign(socket, chat_state: chat_state)}
  end

  def handle_info({:player_joined, player_data}, socket) do
    # Don't add ourselves to the list
    if player_data.character_id != socket.assigns.game_state.character.id do
      online_players =
        [player_data | socket.assigns.online_players]
        |> Enum.uniq_by(& &1.character_id)
        |> Enum.sort_by(& &1.name)

      {:noreply, assign(socket, online_players: online_players)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:player_left, character_id}, socket) do
    online_players =
      Enum.reject(socket.assigns.online_players, &(&1.character_id == character_id))

    {:noreply, assign(socket, online_players: online_players)}
  end

  def handle_info({:request_online_players, requesting_character_id}, socket) do
    # Don't respond to our own request
    if requesting_character_id != socket.assigns.game_state.character.id do
      # Send our player data to the requesting player
      player_data = %{
        name: socket.assigns.character_name,
        level: socket.assigns.game_state.player_stats.level,
        character_id: socket.assigns.game_state.character.id
      }

      Phoenix.PubSub.broadcast(
        Shard.PubSub,
        "player_presence",
        {:player_response, player_data, requesting_character_id}
      )
    end

    {:noreply, socket}
  end

  def handle_info({:player_response, player_data, requesting_character_id}, socket) do
    # Only process responses meant for us
    if requesting_character_id == socket.assigns.game_state.character.id do
      online_players =
        [player_data | socket.assigns.online_players]
        |> Enum.uniq_by(& &1.character_id)
        |> Enum.sort_by(& &1.name)

      {:noreply, assign(socket, online_players: online_players)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def terminate(_reason, socket) do
    # Clean up PubSub subscriptions when the LiveView process ends
    if socket.assigns[:game_state] && socket.assigns.game_state[:character] do
      character = socket.assigns.game_state.character
      unsubscribe_from_character_notifications(character.id)
      unsubscribe_from_player_notifications(character.name)

      # Broadcast that this player has left
      Phoenix.PubSub.broadcast(Shard.PubSub, "player_presence", {:player_left, character.id})
    end

    :ok
  end
end
