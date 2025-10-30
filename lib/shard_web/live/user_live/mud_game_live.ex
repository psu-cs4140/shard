# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule ShardWeb.MudGameLive do
  @moduledoc false
  use ShardWeb, :live_view
  alias Phoenix.PubSub
  alias Phoenix.LiveView.JS
  import ShardWeb.UserLive.Components
  import ShardWeb.UserLive.Components2
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.Commands1
  import ShardWeb.UserLive.MapComponents
  import ShardWeb.UserLive.LegacyMap
  import ShardWeb.UserLive.MonsterComponents
  import ShardWeb.UserLive.CharacterHelpers
  import ShardWeb.UserLive.ItemHelpers
  import ShardWeb.UserLive.MudGameHelpers

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
    with {:ok, character} <- MudGameHelpers.get_character_from_params(params),
         character_name <- MudGameHelpers.get_character_name(params, character),
         {:ok, character} <- MudGameHelpers.load_character_with_associations(character),
         :ok <- MudGameHelpers.setup_tutorial_content(map_id),
         {:ok, socket} <- MudGameHelpers.initialize_game_state(socket, character, map_id, character_name) do
      # Add available_exits after initialization
      socket = assign(socket, available_exits: compute_available_exits(socket.assigns.game_state.player_position))
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
  def handle_event("keypress", %{"key" => key}, socket) do
    # Check if it's a movement key
    case key do
      arrow_key when arrow_key in ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"] ->
        # Use the same execute_movement function that terminal commands use
        movement_result = execute_movement(socket.assigns.game_state, arrow_key)

        {response, updated_game_state, popup_result} =
          case movement_result do
            {resp, state, popup} -> {resp, state, popup}
            {resp, state} -> {resp, state, :no_popup}
          end

        # Add the response to terminal output
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)

        # Handle completion popup
        modal_state =
          case popup_result do
            {:show_completion_popup, message} ->
              %{show: true, type: "dungeon_completion", completion_message: message}

            :no_popup ->
              socket.assigns.modal_state
          end

        {:noreply,
         assign(socket,
           game_state: updated_game_state,
           terminal_state: terminal_state,
           modal_state: modal_state,
           available_exits: compute_available_exits(updated_game_state.player_position)
         )}

      _ ->
        # Non-movement key, do nothing
        {:noreply, socket}
    end
  end

  def handle_event("submit_command", %{"command" => %{"text" => command_text}}, socket) do
    trimmed_command = String.trim(command_text)

    if trimmed_command != "" do
      # Add command to history
      new_history = [trimmed_command | socket.assigns.terminal_state.command_history]

      # Process the command and get response and updated game state
      {response, updated_game_state} = process_command(trimmed_command, socket.assigns.game_state)

      # Check if stats changed significantly and save to database
      old_stats = socket.assigns.game_state.player_stats
      new_stats = updated_game_state.player_stats

      if stats_changed_significantly?(old_stats, new_stats) do
        save_character_stats(updated_game_state.character, new_stats)
      end

      # Add command and response to output
      new_output =
        socket.assigns.terminal_state.output ++
          ["> #{trimmed_command}"] ++
          response ++
          [""]

      terminal_state = %{
        output: new_output,
        command_history: new_history,
        current_command: ""
      }

      socket = assign(socket, game_state: updated_game_state, terminal_state: terminal_state)

      # Auto-scroll terminal to bottom
      socket = push_event(socket, "scroll_to_bottom", %{target: "terminal-output"})

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_command", %{"command" => %{"text" => command_text}}, socket) do
    terminal_state = Map.put(socket.assigns.terminal_state, :current_command, command_text)
    {:noreply, assign(socket, terminal_state: terminal_state)}
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
        socket = MudGameHelpers.add_message(socket, "Character stats saved successfully.")
        {:noreply, socket}

      {:error, _error} ->
        socket = MudGameHelpers.add_message(socket, "Failed to save character stats.")
        {:noreply, socket}
    end
  end

  def handle_event("use_hotbar_item", %{"slot" => slot_number}, socket) do
    slot_key = String.to_atom("slot_#{slot_number}")
    item = Map.get(socket.assigns.game_state.hotbar, slot_key)

    case item do
      nil ->
        socket = MudGameHelpers.add_message(socket, "Hotbar slot #{slot_number} is empty.")
        {:noreply, socket}

      item ->
        {response, updated_game_state} = use_item(socket.assigns.game_state, item)

        # Add response to terminal
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)

        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}
    end
  end

  def handle_event("equip_item", %{"item_id" => item_id}, socket) do
    # Find item in inventory
    item =
      Enum.find(socket.assigns.game_state.inventory_items, fn inv_item ->
        to_string(Map.get(inv_item, :id)) == item_id
      end)

    case item do
      nil ->
        socket = MudGameHelpers.add_message(socket, "Item not found in inventory.")
        {:noreply, socket}

      item ->
        {response, updated_game_state} = equip_item(socket.assigns.game_state, item)

        # Add response to terminal
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)

        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}
    end
  end

  # (C) Handle clicking an exit button to move rooms
  @impl true
  def handle_event("click_exit", %{"dir" => dir}, socket) do
    key = dir_to_key(dir)
    player_position = socket.assigns.game_state.player_position
    map_data = socket.assigns.game_state.map_data

    new_position =
      case key do
        nil -> player_position
        _ -> calc_position(player_position, key, map_data)
      end

    terminal_state =
      if new_position != player_position do
        msg = "You move #{dir}."
        Map.update!(socket.assigns.terminal_state, :output, &(&1 ++ [msg, ""]))
      else
        socket.assigns.terminal_state
      end

    game_state = %{
      socket.assigns.game_state
      | player_position: new_position
    }

    {:noreply,
     assign(socket,
       game_state: game_state,
       terminal_state: terminal_state,
       available_exits: compute_available_exits(game_state.player_position)
     )}
  end


  @impl true
  def handle_info({:noise, text}, socket) do
    socket = MudGameHelpers.add_message(socket, text)
    {:noreply, socket}
  end

  def handle_info({:area_heal, xx, msg}, socket) do
    socket =
      socket
      |> MudGameHelpers.add_message(msg)
      |> MudGameHelpers.add_message("Area heal effect: #{xx} damage healed")

    current_stats = socket.assigns.game_state.player_stats
    max_health = current_stats.max_health
    current_health = current_stats.health

    if current_health < max_health do
      new_health = min(current_health + xx, max_health)

      updated_stats = %{current_stats | health: new_health}
      updated_game_state = %{socket.assigns.game_state | player_stats: updated_stats}

      # Save updated stats to database
      save_character_stats(socket.assigns.game_state.character, updated_stats)

      {:noreply, assign(socket, :game_state, updated_game_state)}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:update_game_state, new_game_state}, socket) do
    {:noreply, assign(socket, :game_state, new_game_state)}
  end
end
