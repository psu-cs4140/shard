defmodule ShardWeb.UserLive.PresenceHandlers do
  @moduledoc """
  Handles player presence and PubSub message events for the MUD game.
  """

  alias Phoenix.PubSub
  import ShardWeb.UserLive.Commands3
  import ShardWeb.UserLive.MudGameHandlers

  def handle_chat_message({:chat_message, message_data}, socket) do
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

  def handle_player_joined({:player_joined, player_data}, socket) do
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

  def handle_player_left({:player_left, character_id}, socket) do
    online_players =
      Enum.reject(socket.assigns.online_players, &(&1.character_id == character_id))

    {:noreply, assign(socket, online_players: online_players)}
  end

  def handle_request_online_players({:request_online_players, requesting_character_id}, socket) do
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

  def handle_player_response({:player_response, player_data, requesting_character_id}, socket) do
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

  def handle_poke_notification({:poke_notification, poker_name}, socket) do
    terminal_state = handle_poke_notification(socket.assigns.terminal_state, poker_name)

    # Auto-scroll terminal to bottom
    socket = push_event(socket, "scroll_to_bottom", %{target: "terminal-output"})

    {:noreply, assign(socket, terminal_state: terminal_state)}
  end

  def handle_noise_info({:noise, text}, socket) do
    case handle_noise_info({:noise, text}, socket) do
      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_area_heal_info({:area_heal, xx, msg}, socket) do
    case handle_area_heal_info({:area_heal, xx, msg}, socket) do
      {:noreply, socket, updated_game_state, terminal_state} ->
        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}

      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_update_game_state_info({:update_game_state, new_game_state}, socket) do
    case handle_update_game_state_info({:update_game_state, new_game_state}, socket) do
      {:noreply, socket, game_state} ->
        {:noreply, assign(socket, game_state: game_state)}

      result ->
        result
    end
  end

  def handle_combat_event_info({:combat_event, event}, socket) do
    case handle_combat_event_info({:combat_event, event}, socket) do
      {:noreply, socket, updated_game_state, terminal_state} ->
        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}

      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_player_joined_combat_info({:player_joined_combat, player_name}, socket) do
    case handle_player_joined_combat_info({:player_joined_combat, player_name}, socket) do
      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_player_left_combat_info({:player_left_combat, player_name}, socket) do
    case handle_player_left_combat_info({:player_left_combat, player_name}, socket) do
      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def handle_combat_action_info({:combat_action, event}, socket) do
    case handle_combat_action_info({:combat_action, event}, socket) do
      {:noreply, socket, terminal_state} ->
        {:noreply, assign(socket, terminal_state: terminal_state)}

      result ->
        result
    end
  end

  def setup_player_presence(socket, character, character_name) do
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

    socket
  end

  def cleanup_player_presence(socket) do
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
