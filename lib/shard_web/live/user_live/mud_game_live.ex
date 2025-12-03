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
  import ShardWeb.UserLive.MudGameHelpers
  import ShardWeb.UserLive.MudGameEventHandlers
  import ShardWeb.UserLive.MudGamePubSubHandlers
  import ShardWeb.UserLive.MudGameRender
  import ShardWeb.UserLive.MudGameLiveMultiplayerComponents

  @impl true
  # credo:disable-for-next-line Credo.Check.Refactor.CyclomaticComplexity, Credo.Check.Refactor.Nesting
  def mount(%{"character_id" => character_id} = params, _session, socket) do
    with {:ok, character} <- ShardWeb.UserLive.MudGameHelpers.get_character_from_params(params),
         character_name <- get_character_name(params, character),
         {:ok, character} <- load_character_with_associations(character),
         {:ok, socket} <- initialize_game_state(socket, character, character_id, character_name) do
      # Use zone_id from URL params if provided, otherwise fall back to character's current_zone_id
      zone_id =
        case params["zone_id"] do
          nil -> character.current_zone_id || 1
          zone_id_str -> String.to_integer(zone_id_str)
        end

      # Load the zone information to get the zone name
      zone = Shard.Map.get_zone!(zone_id)
      {x, y} = socket.assigns.game_state.player_position

      case Shard.Map.get_room_by_coordinates(zone_id, x, y, 0) do
        nil ->
          # If no room exists at current position, find starting room and save it
          case Shard.Map.get_zone_starting_room(zone_id) do
            # No starting room found, continue without saving
            nil ->
              :ok

            room ->
              Shard.Map.update_player_position(character.id, zone_id, room)
          end

        room ->
          # Save current position if player doesn't have a saved position
          case Shard.Map.get_player_position(character.id, zone_id) do
            nil -> Shard.Map.update_player_position(character.id, zone_id, room)
            # Position already exists, don't overwrite
            _existing -> :ok
          end
      end

      # Subscribe to the global chat topic
      Phoenix.PubSub.subscribe(Shard.PubSub, "global_chat")
      # Subscribe to player presence updates
      Phoenix.PubSub.subscribe(Shard.PubSub, "player_presence")

      # Initialize online players list
      socket = assign(socket, online_players: [], zone_name: zone.name)

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
         |> push_navigate(to: ~p"/zones")}
    end
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    render_main_layout(assigns)
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
    {:noreply, socket, updated_game_state, terminal_state, player_position} =
      handle_keypress(params, socket)

    {:noreply,
     assign(socket,
       game_state: updated_game_state,
       terminal_state: terminal_state,
       available_exits: compute_available_exits(player_position, updated_game_state)
     )}
  end

  def handle_event("submit_command", params, socket) do
    case handle_submit_command(params, socket) do
      {:noreply, socket, updated_game_state, terminal_state} ->
        # Reload inventory to ensure it's synced with database
        updated_inventory =
          ShardWeb.UserLive.CharacterHelpers.load_character_inventory(
            updated_game_state.character
          )

        final_game_state = %{updated_game_state | inventory_items: updated_inventory}

        socket = assign(socket, game_state: final_game_state, terminal_state: terminal_state)

        # Auto-scroll terminal to bottom
        socket = push_event(socket, "scroll_to_bottom", %{target: "terminal-output"})

        {:noreply, socket}

      {:noreply, socket} ->
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

  def handle_event("submit_chat", params, socket) do
    handle_submit_chat(params, socket)
  end

  def handle_event("update_chat", params, socket) do
    handle_update_chat(params, socket)
  end

  def handle_event("save_character_stats", params, socket) do
    handle_save_character_stats(params, socket)
  end

  def handle_event("use_hotbar_item", params, socket) do
    {:noreply, socket, updated_game_state, terminal_state} =
      handle_use_hotbar_item(params, socket)

    {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}
  end

  def handle_event("equip_item", params, socket) do
    {:noreply, socket, updated_game_state, terminal_state} = handle_equip_item(params, socket)
    {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}
  end

  def handle_event("drop_item", params, socket) do
    handle_drop_item(params, socket)
  end

  def handle_event("show_hotbar_modal", params, socket) do
    handle_show_hotbar_modal(params, socket)
  end

  def handle_event("set_hotbar_from_modal", params, socket) do
    handle_set_hotbar_from_modal(params, socket)
  end

  # (C) Handle clicking an exit button to move rooms
  @impl true
  def handle_event("click_exit", params, socket) do
    {:noreply, socket, game_state, terminal_state, player_position} =
      handle_click_exit(params, socket)

    {:noreply,
     assign(socket,
       game_state: game_state,
       terminal_state: terminal_state,
       available_exits: compute_available_exits(player_position, game_state)
     )}
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

  def handle_info({:chat_message, message_data}, socket) do
    handle_chat_message(message_data, socket)
  end

  def handle_info({:poke_notification, poker_name}, socket) do
    handle_poke_notification(poker_name, socket)
  end

  def handle_info({:player_joined, player_data}, socket) do
    handle_player_joined(player_data, socket)
  end

  def handle_info({:player_left, character_id}, socket) do
    handle_player_left(character_id, socket)
  end

  def handle_info({:request_online_players, requesting_character_id}, socket) do
    handle_request_online_players(requesting_character_id, socket)
  end

  def handle_info({:player_response, player_data, requesting_character_id}, socket) do
    handle_player_response(player_data, requesting_character_id, socket)
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

  # Helper function to get item name safely
  defp get_item_name(item) do
    cond do
      item.item && item.item.name -> item.item.name
      item.name -> item.name
      true -> "Unknown Item"
    end
  end
end
