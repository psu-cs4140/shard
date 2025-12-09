defmodule ShardWeb.GamblingLive.Index do
  use ShardWeb, :live_view

  alias Shard.Gambling
  alias Shard.Gambling.CoinFlipServer
  alias Shard.Characters
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Shard.PubSub, "coin_flip")
    end

    current_user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(current_user.id)

    socket =
      socket
      |> assign(:characters, characters)
      |> assign(:selected_character_id, get_first_character_id(characters))
      |> assign(:bet_amount, "")
      |> assign(:selected_side, nil)
      |> assign(:last_result, nil)
      |> assign(:show_result_modal, false)

    socket = load_flip_data(socket)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_character", %{"character_id" => character_id}, socket) do
    socket =
      socket
      |> assign(:selected_character_id, String.to_integer(character_id))
      |> load_flip_data()

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_bet_amount", %{"value" => amount}, socket) do
    {:noreply, assign(socket, :bet_amount, amount)}
  end

  @impl true
  def handle_event("select_side", %{"side" => side}, socket) do
    {:noreply, assign(socket, :selected_side, side)}
  end

  @impl true
  def handle_event("place_bet", _params, socket) do
    character_id = socket.assigns.selected_character_id
    amount = socket.assigns.bet_amount
    side = socket.assigns.selected_side
    flip_info = socket.assigns.flip_info

    cond do
      is_nil(character_id) ->
        {:noreply, put_flash(socket, :error, "Please select a character")}

      is_nil(side) ->
        {:noreply, put_flash(socket, :error, "Please select heads or tails")}

      amount == "" or amount == "0" ->
        {:noreply, put_flash(socket, :error, "Please enter a bet amount")}

      true ->
        case Gambling.create_bet(%{
               character_id: character_id,
               flip_id: flip_info.flip_id,
               amount: amount,
               prediction: side
             }) do
          {:ok, _bet} ->
            socket =
              socket
              |> assign(:bet_amount, "")
              |> assign(:selected_side, nil)
              |> load_flip_data()
              |> put_flash(:info, "Bet placed successfully! Good luck!")

            {:noreply, socket}

          {:error, :insufficient_gold} ->
            {:noreply, put_flash(socket, :error, "Not enough gold!")}

          {:error, :character_not_found} ->
            {:noreply, put_flash(socket, :error, "Character not found")}

          {:error, :invalid_amount} ->
            {:noreply, put_flash(socket, :error, "Invalid bet amount")}

          {:error, %Ecto.Changeset{}} ->
            {:noreply, put_flash(socket, :error, "Failed to place bet. Please try again.")}
        end
    end
  end

  @impl true
  def handle_event("close_result_modal", _params, socket) do
    {:noreply, assign(socket, :show_result_modal, false)}
  end

  @impl true
  def handle_event("set_max_bet", _params, socket) do
    character_id = socket.assigns.selected_character_id

    if character_id do
      character = Enum.find(socket.assigns.characters, &(&1.id == character_id))
      {:noreply, assign(socket, :bet_amount, Integer.to_string(character.gold))}
    else
      {:noreply, socket}
    end
  end

  # PubSub callbacks
  @impl true
  def handle_info({:countdown_update, %{seconds_remaining: seconds}}, socket) do
    socket = assign(socket, :seconds_remaining, seconds)
    {:noreply, socket}
  end

  @impl true
  def handle_info({:new_flip, %{flip_id: flip_id, next_flip_at: next_flip_at}}, socket) do
    socket =
      socket
      |> assign(:flip_info, %{flip_id: flip_id, next_flip_at: next_flip_at})
      |> assign(:last_result, nil)
      |> load_flip_data()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:flip_result, %{result: result, stats: stats}}, socket) do
    socket =
      socket
      |> assign(:last_result, %{result: result, stats: stats})
      |> assign(:show_result_modal, true)
      |> load_flip_data()

    # Reload characters to update gold amounts
    current_user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(current_user.id)

    socket = assign(socket, :characters, characters)

    {:noreply, socket}
  end

  # Private helpers

  defp load_flip_data(socket) do
    flip_info = CoinFlipServer.get_current_flip()
    seconds_remaining = CoinFlipServer.seconds_until_flip()

    character_id = socket.assigns.selected_character_id

    {current_bet, bet_history, statistics} =
      if character_id do
        current_bet = Gambling.get_pending_bet(character_id, flip_info.flip_id)
        bet_history = Gambling.get_character_bets(character_id, 5)
        statistics = Gambling.get_statistics(character_id)
        {current_bet, bet_history, statistics}
      else
        {nil, [],
         %{total_bets: 0, total_won: 0, total_wagered: 0, total_winnings: 0, win_rate: 0}}
      end

    socket
    |> assign(:flip_info, flip_info)
    |> assign(:seconds_remaining, seconds_remaining)
    |> assign(:current_bet, current_bet)
    |> assign(:bet_history, bet_history)
    |> assign(:statistics, statistics)
  end

  defp get_first_character_id([]), do: nil
  defp get_first_character_id([first | _]), do: first.id

  # Helper functions for the template
  def format_countdown(seconds) when seconds >= 60 do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}:#{String.pad_leading(Integer.to_string(secs), 2, "0")}"
  end

  def format_countdown(seconds), do: "0:#{String.pad_leading(Integer.to_string(seconds), 2, "0")}"

  def result_color("won"), do: "text-green-400 bg-green-900/30 border-green-700/50"
  def result_color("lost"), do: "text-red-500 bg-red-900/30 border-red-700/50"
  def result_color(_), do: "text-gray-400 bg-gray-800/50 border-gray-600/50"

  def result_label("won"), do: "Won"
  def result_label("lost"), do: "Lost"
  def result_label(_), do: "Pending"

  # Helper functions for bet amount parsing (same logic as Gambling module)
  def valid_bet_amount?(amount) when is_binary(amount) do
    case Integer.parse(amount) do
      {num, _} when num > 0 -> true
      _ -> false
    end
  end

  def valid_bet_amount?(_), do: false

  def parse_bet_amount(amount) when is_binary(amount) do
    case Integer.parse(amount) do
      {num, _} -> num
      _ -> 0
    end
  end

  def parse_bet_amount(amount) when is_integer(amount), do: amount
  def parse_bet_amount(_), do: 0
end
