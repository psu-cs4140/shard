defmodule ShardWeb.BlackjackTableLive do
  @moduledoc """
  LiveView for the Dark Blackjack table interface.
  Supports 4-6 players with real-time gameplay.
  """
  use ShardWeb, :live_view

  alias Shard.Gambling.BlackjackServer
  alias Shard.Characters
  alias Phoenix.PubSub

  @impl true
  def mount(%{"game_id" => game_id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Shard.PubSub, "blackjack:#{game_id}")
    end

    current_user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(current_user.id)

    case BlackjackServer.get_game(game_id) do
      {:ok, game_data} ->
        socket =
          socket
          |> assign(:game_id, game_id)
          |> assign(:game_data, game_data)
          |> assign(:characters, characters)
          |> assign(:selected_character_id, get_first_character_id(characters))
          |> assign(:bet_amount, "")
          |> assign(:show_join_modal, false)

        {:ok, socket}

      {:error, :game_not_found} ->
        socket =
          socket
          |> put_flash(:error, "Game not found")
          |> redirect(to: "/gambling")

        {:ok, socket}
    end
  end

  @impl true
  def handle_event("select_character", %{"character_id" => character_id}, socket) do
    {:noreply, assign(socket, :selected_character_id, String.to_integer(character_id))}
  end

  @impl true
  def handle_event("update_bet_amount", %{"value" => amount}, socket) do
    {:noreply, assign(socket, :bet_amount, amount)}
  end

  @impl true
  def handle_event("join_table", _params, socket) do
    character_id = socket.assigns.selected_character_id
    game_id = socket.assigns.game_id

    # Find an available position (1-6)
    taken_positions = Enum.map(socket.assigns.game_data.hands, & &1.position)
    available_position = Enum.find(1..6, &(&1 not in taken_positions))

    if available_position do
      case BlackjackServer.join_game(game_id, character_id, available_position) do
        :ok ->
          {:noreply,
           socket
           |> assign(:show_join_modal, false)
           |> put_flash(:info, "Joined table at position #{available_position}!")}

        {:error, reason} ->
          {:noreply, put_flash(socket, :error, "Failed to join table: #{reason}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Table is full!")}
    end
  end

  @impl true
  def handle_event("place_bet", _params, socket) do
    character_id = socket.assigns.selected_character_id
    game_id = socket.assigns.game_id
    amount = socket.assigns.bet_amount

    cond do
      is_nil(character_id) ->
        {:noreply, put_flash(socket, :error, "Please select a character")}

      amount == "" or amount == "0" ->
        {:noreply, put_flash(socket, :error, "Please enter a bet amount")}

      true ->
        case BlackjackServer.place_bet(game_id, character_id, amount) do
          :ok ->
            {:noreply,
             socket
             |> assign(:bet_amount, "")
             |> put_flash(:info, "Bet placed successfully!")}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Failed to place bet: #{reason}")}
        end
    end
  end

  @impl true
  def handle_event("hit", _params, socket) do
    character_id = socket.assigns.selected_character_id
    game_id = socket.assigns.game_id

    case BlackjackServer.hit(game_id, character_id) do
      :ok -> {:noreply, socket}
      {:error, reason} -> {:noreply, put_flash(socket, :error, "Cannot hit: #{reason}")}
    end
  end

  @impl true
  def handle_event("stand", _params, socket) do
    character_id = socket.assigns.selected_character_id
    game_id = socket.assigns.game_id

    case BlackjackServer.stand(game_id, character_id) do
      :ok -> {:noreply, socket}
      {:error, reason} -> {:noreply, put_flash(socket, :error, "Cannot stand: #{reason}")}
    end
  end

  @impl true
  def handle_event("leave_table", _params, socket) do
    character_id = socket.assigns.selected_character_id
    game_id = socket.assigns.game_id

    case BlackjackServer.leave_game(game_id, character_id) do
      :ok ->
        {:noreply, put_flash(socket, :info, "Left the table")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to leave table: #{reason}")}
    end
  end

  @impl true
  def handle_event("show_join_modal", _params, socket) do
    {:noreply, assign(socket, :show_join_modal, true)}
  end

  @impl true
  def handle_event("hide_join_modal", _params, socket) do
    {:noreply, assign(socket, :show_join_modal, false)}
  end

  # PubSub event handlers
  @impl true
  def handle_info({:game_created, _data}, socket) do
    # Refresh game data
    {:noreply, update_game_data(socket)}
  end

  @impl true
  def handle_info({:player_joined, _data}, socket) do
    {:noreply, update_game_data(socket)}
  end

  @impl true
  def handle_info({:player_left, _data}, socket) do
    {:noreply, update_game_data(socket)}
  end

  @impl true
  def handle_info({:bet_placed, _data}, socket) do
    {:noreply, update_game_data(socket)}
  end

  @impl true
  def handle_info({:dealing_started, _data}, socket) do
    {:noreply, update_game_data(socket)}
  end

  @impl true
  def handle_info({:card_dealt, _data}, socket) do
    {:noreply, update_game_data(socket)}
  end

  @impl true
  def handle_info({:player_turn, _data}, socket) do
    {:noreply, update_game_data(socket)}
  end

  @impl true
  def handle_info({:player_stood, _data}, socket) do
    {:noreply, update_game_data(socket)}
  end

  @impl true
  def handle_info({:game_finished, _data}, socket) do
    {:noreply, update_game_data(socket)}
  end

  @impl true
  def handle_info({:game_reset, _data}, socket) do
    {:noreply, update_game_data(socket)}
  end

  # Helper functions

  defp update_game_data(socket) do
    case BlackjackServer.get_game(socket.assigns.game_id) do
      {:ok, game_data} ->
        assign(socket, :game_data, game_data)

      {:error, _reason} ->
        socket
    end
  end

  defp get_first_character_id([]), do: nil
  defp get_first_character_id([first | _]), do: first.id

  # Template helpers

  def format_card(card) do
    case card do
      %{rank: "A", suit: _suit} -> "🂡"
      %{rank: "2", suit: _suit} -> "🂢"
      %{rank: "3", suit: _suit} -> "🂣"
      %{rank: "4", suit: _suit} -> "🂤"
      %{rank: "5", suit: _suit} -> "🂥"
      %{rank: "6", suit: _suit} -> "🂦"
      %{rank: "7", suit: _suit} -> "🂧"
      %{rank: "8", suit: _suit} -> "🂨"
      %{rank: "9", suit: _suit} -> "🂩"
      %{rank: "10", suit: _suit} -> "🂪"
      %{rank: "J", suit: _suit} -> "🂫"
      %{rank: "Q", suit: _suit} -> "🂭"
      %{rank: "K", suit: _suit} -> "🂮"
      _ -> "🂠"
    end
  end

  def calculate_hand_value(cards) do
    Shard.Gambling.Blackjack.calculate_hand_value(cards)
  end

  def is_player_turn?(_game_data, _character_id) do
    # This would need to be implemented based on game state
    false
  end

  def get_player_hand(game_data, character_id) do
    Enum.find(game_data.hands, &(&1.character_id == character_id))
  end

  def can_place_bet?(game_data, character_id) do
    hand = get_player_hand(game_data, character_id)
    hand && hand.status == "betting" && game_data.phase == "betting"
  end

  def can_take_action?(game_data, character_id) do
    hand = get_player_hand(game_data, character_id)
    hand && hand.status == "playing" && game_data.phase == "playing"
  end

  # Template helper functions
  def player_position_class(1), do: "bottom-4 left-1/2 transform -translate-x-1/2"
  def player_position_class(2), do: "bottom-16 right-16"
  def player_position_class(3), do: "top-16 right-16"
  def player_position_class(4), do: "top-4 left-1/2 transform -translate-x-1/2"
  def player_position_class(5), do: "top-16 left-16"
  def player_position_class(6), do: "bottom-16 left-16"

  def status_color("betting"), do: "text-yellow-400"
  def status_color("playing"), do: "text-green-400"
  def status_color("stood"), do: "text-blue-400"
  def status_color("busted"), do: "text-red-400"
  def status_color("blackjack"), do: "text-purple-400"
  def status_color(_), do: "text-gray-400"
end
