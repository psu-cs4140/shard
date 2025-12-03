defmodule ShardWeb.UserLive.MudGamePubSubHandlers do
  @moduledoc """
  PubSub message handlers for the MUD game live view.
  """

  alias Phoenix.Component
  alias Phoenix.LiveView

  def handle_chat_message(message_data, socket) do
    formatted_message =
      "[#{message_data.timestamp}] #{message_data.character_name}:#{message_data.character_id}: #{message_data.text}"

    chat_state = socket.assigns.chat_state
    updated_messages = chat_state.messages ++ [formatted_message]
    updated_chat_state = Map.put(chat_state, :messages, updated_messages)

    {:noreply, Component.assign(socket, chat_state: updated_chat_state)}
  end

  def handle_poke_notification(poker_name, socket) do
    terminal_state = add_poke_message(socket.assigns.terminal_state, poker_name)
    socket = LiveView.push_event(socket, "scroll_to_bottom", %{target: "terminal-output"})
    {:noreply, Component.assign(socket, terminal_state: terminal_state)}
  end

  def handle_player_joined(player_data, socket) do
    if player_data.character_id != socket.assigns.game_state.character.id do
      online_players =
        [player_data | socket.assigns.online_players]
        |> Enum.uniq_by(& &1.character_id)
        |> Enum.sort_by(& &1.name)

      {:noreply, Component.assign(socket, online_players: online_players)}
    else
      {:noreply, socket}
    end
  end

  def handle_player_left(character_id, socket) do
    online_players =
      Enum.reject(socket.assigns.online_players, &(&1.character_id == character_id))

    {:noreply, Component.assign(socket, online_players: online_players)}
  end

  def handle_request_online_players(requesting_character_id, socket) do
    if requesting_character_id != socket.assigns.game_state.character.id do
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

  def handle_player_response(player_data, requesting_character_id, socket) do
    if requesting_character_id == socket.assigns.game_state.character.id do
      online_players =
        [player_data | socket.assigns.online_players]
        |> Enum.uniq_by(& &1.character_id)
        |> Enum.sort_by(& &1.name)

      {:noreply, Component.assign(socket, online_players: online_players)}
    else
      {:noreply, socket}
    end
  end

  defp add_poke_message(terminal_state, poker_name) do
    new_output = terminal_state.output ++ ["#{poker_name} pokes you!", ""]
    Map.put(terminal_state, :output, new_output)
  end
end
