defmodule Shard.Gambling.Blackjack do
  @moduledoc """
  Context for managing blackjack game logic and betting.
  """

  import Ecto.Query
  alias Shard.Repo
  alias Shard.Gambling.{BlackjackGame, BlackjackHand}
  alias Shard.Gambling.{BlackjackGame, BlackjackHand}
  alias Shard.Gambling.BlackjackServer.GameState
  alias Shard.Characters.Character

  @doc """
  Calculate the value of a blackjack hand.
  Returns {value, is_soft} where is_soft indicates if ace is counting as 11.
  """
  def calculate_hand_value(cards) when is_list(cards) do
    {total, aces} =
      Enum.reduce(cards, {0, 0}, fn card, {sum, ace_count} ->
        rank = Map.get(card, "rank") || Map.get(card, :rank)

        case rank do
          "A" -> {sum, ace_count + 1}
          "K" -> {sum + 10, ace_count}
          "Q" -> {sum + 10, ace_count}
          "J" -> {sum + 10, ace_count}
          rank -> {sum + String.to_integer(to_string(rank)), ace_count}
        end
      end)

    # Handle aces (can be 1 or 11)
    {final_total, soft} = adjust_for_aces(total, aces)
    {final_total, soft}
  end

  @doc """
  Check if a hand is blackjack (21 with exactly 2 cards)
  """
  def is_blackjack?(cards) when is_list(cards) do
    {value, _soft} = calculate_hand_value(cards)
    length(cards) == 2 && value == 21
  end

  @doc """
  Check if a hand is busted (over 21)
  """
  def is_busted?(cards) when is_list(cards) do
    {value, _soft} = calculate_hand_value(cards)
    value > 21
  end

  @doc """
  Deal initial cards to all players and dealer.
  Returns {updated_hands, dealer_cards, remaining_deck}
  """
  def deal_initial_cards(hands, deck) when is_map(hands) and is_list(deck) do
    # Deal two cards to each player, then two to dealer (one face up, one face down)
    {player_cards, deck_after_players} = deal_to_players(hands, deck, 2)
    {dealer_cards, final_deck} = deal_to_dealer(deck_after_players, 2)

    {player_cards, dealer_cards, final_deck}
  end

  @doc """
  Deal a card to a specific player.
  Returns {updated_hand, remaining_deck}
  """
  def deal_card_to_player(hand, deck) when is_list(deck) do
    [card | rest_deck] = deck
    updated_cards = hand.hand_cards ++ [card]
    updated_hand = %{hand | hand_cards: updated_cards}

    {updated_hand, rest_deck}
  end

  @doc """
  Dealer plays according to standard rules (hit on 16, stand on 17).
  Returns final dealer hand.
  """
  def play_dealer_turn(dealer_hand, deck) do
    {value, _soft} = calculate_hand_value(dealer_hand)

    cond do
      # Already busted
      value > 21 ->
        dealer_hand

      # Blackjack or 21
      value == 21 ->
        dealer_hand

      # Stand
      value >= 17 ->
        dealer_hand

      value <= 16 ->
        # Hit - recursively play until stand or bust
        [card | rest_deck] = deck
        new_hand = dealer_hand ++ [card]
        play_dealer_turn(new_hand, rest_deck)
    end
  end

  @doc """
  Determine the outcome of a hand vs dealer.
  Returns {:win | :lose | :push | :blackjack, payout_multiplier}
  """
  def determine_outcome(player_cards, dealer_cards) do
    player_blackjack = is_blackjack?(player_cards)
    dealer_blackjack = is_blackjack?(dealer_cards)
    player_busted = is_busted?(player_cards)
    dealer_busted = is_busted?(dealer_cards)

    {player_value, _} = calculate_hand_value(player_cards)
    {dealer_value, _} = calculate_hand_value(dealer_cards)

    cond do
      # 3:2 payout
      player_blackjack && !dealer_blackjack -> {:blackjack_win, 2.5}
      dealer_blackjack && !player_blackjack -> {:lost, 0}
      player_busted -> {:lost, 0}
      dealer_busted -> {:won, 2}
      player_value > dealer_value -> {:won, 2}
      player_value < dealer_value -> {:lost, 0}
      # Tie
      true -> {:push, 1}
    end
  end

  @doc """
  Place a bet for a character in a blackjack game.
  """
  def place_bet(game_id, character_id, amount) do
    amount = parse_amount(amount)

    with {:ok, amount} <- validate_amount(amount),
         character when not is_nil(character) <- Repo.get(Character, character_id),
         :ok <- validate_sufficient_gold(character, amount),
         hand when not is_nil(hand) <- get_hand(game_id, character_id),
         :ok <- validate_betting_phase(hand),
         {:ok, _character} <- deduct_gold(character, amount),
         {:ok, updated_hand} <- update_hand_bet(hand, amount) do
      {:ok, updated_hand}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :hand_not_found}
    end
  end

  @doc """
  Process payouts for all hands in a completed game.
  """
  def process_payouts(game_id, dealer_cards) do
    hands = get_game_hands(game_id)

    Repo.transaction(fn ->
      Enum.each(hands, fn hand ->
        if hand.bet_amount > 0 do
          outcome = determine_outcome(hand.hand_cards, dealer_cards)
          payout = calculate_payout(hand.bet_amount, outcome)

          # Update hand with outcome and payout
          hand
          |> BlackjackHand.changeset(%{outcome: Atom.to_string(elem(outcome, 0)), payout: payout})
          |> Repo.update!()

          # Add payout to character if they won
          if payout > 0 do
            character = Repo.get!(Character, hand.character_id)

            character
            |> Character.changeset(%{gold: character.gold + payout})
            |> Repo.update!()

            # Check for blackjack achievements
            case outcome do
              {:blackjack_win, _} ->
                Shard.Achievements.check_gambling_achievements(character.user_id, :blackjack)

              {:won, _} ->
                Shard.Achievements.check_gambling_achievements(character.user_id, :won)

              _ ->
                :ok
            end
          else
            # Check for loss achievement
            character = Repo.get!(Character, hand.character_id)
            Shard.Achievements.check_gambling_achievements(character.user_id, :lost)
          end
        end
      end)
    end)
  end

  @doc """
  Get all hands for a game.
  """
  def get_game_hands(game_id) do
    from(h in BlackjackHand,
      join: g in BlackjackGame,
      on: g.id == h.blackjack_game_id,
      where: g.game_id == ^game_id,
      preload: [:character]
    )
    |> Repo.all()
  end

  @doc """
  Get a specific hand for a character in a game.
  """
  def get_hand(game_id, character_id) do
    from(h in BlackjackHand,
      join: g in BlackjackGame,
      on: g.id == h.blackjack_game_id,
      where: g.game_id == ^game_id and h.character_id == ^character_id
    )
    |> Repo.one()
  end

  @doc """
  Update game status.
  """
  def update_game_status(game_id, status) do
    Repo.get_by(BlackjackGame, game_id: game_id)
    |> case do
      nil ->
        {:error, :game_not_found}

      game ->
        game
        |> BlackjackGame.changeset(%{status: status})
        |> Repo.update()
    end
  end

  # Private helper functions

  defp adjust_for_aces(total, aces) when aces > 0 do
    # Try to use one ace as 11 (soft total)
    # One ace as 11, others as 1
    soft_total = total + 11 + (aces - 1)

    if soft_total <= 21 do
      {soft_total, true}
    else
      # All aces as 1
      {total + aces, false}
    end
  end

  defp adjust_for_aces(total, _aces), do: {total, false}

  defp deal_to_players(hands, deck, cards_per_player) do
    Enum.reduce(hands, {hands, deck}, fn {character_id, hand}, {hands_acc, deck_acc} ->
      {updated_hand, remaining_deck} = deal_cards_to_hand(hand, deck_acc, cards_per_player)
      {Map.put(hands_acc, character_id, updated_hand), remaining_deck}
    end)
  end

  defp deal_to_dealer(deck, count) do
    {cards, remaining_deck} = Enum.split(deck, count)
    {cards, remaining_deck}
  end

  defp deal_cards_to_hand(hand, deck, count) do
    {cards, remaining_deck} = Enum.split(deck, count)
    updated_hand = %{hand | hand_cards: hand.hand_cards ++ cards}
    {updated_hand, remaining_deck}
  end

  defp parse_amount(amount) when is_integer(amount), do: amount

  defp parse_amount(amount) when is_binary(amount) do
    case Integer.parse(amount) do
      {num, _} -> num
      :error -> :error
    end
  end

  defp parse_amount(_), do: :error

  defp validate_amount(amount) when is_integer(amount) and amount > 0, do: {:ok, amount}
  defp validate_amount(:error), do: {:error, :invalid_amount}
  defp validate_amount(_), do: {:error, :invalid_amount}

  defp validate_sufficient_gold(%Character{gold: gold}, amount) when gold >= amount, do: :ok
  defp validate_sufficient_gold(_character, _amount), do: {:error, :insufficient_gold}

  defp validate_betting_phase(hand) do
    if hand.status == "betting", do: :ok, else: {:error, :not_betting_phase}
  end

  defp deduct_gold(character, amount) do
    character
    |> Character.changeset(%{gold: character.gold - amount})
    |> Repo.update()
  end

  defp update_hand_bet(hand, amount) do
    hand
    |> BlackjackHand.changeset(%{bet_amount: amount, status: "playing"})
    |> Repo.update()
  end

  defp calculate_payout(bet_amount, {_outcome, multiplier}) do
    round(bet_amount * multiplier)
  end

  @doc """
  Create and shuffle a standard 52-card deck
  """
  def shuffle_deck do
    suits = ["hearts", "diamonds", "clubs", "spades"]
    ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

    deck =
      for suit <- suits, rank <- ranks do
        %{suit: suit, rank: rank}
      end

    Enum.shuffle(deck)
  end

  @doc """
  Restore all active games from database into GameState structs.
  Does NOT start timers.
  """
  def restore_active_games do
    # Load games that aren't finished
    games =
      Repo.all(
        from g in BlackjackGame,
          where: g.status != "finished",
          preload: [:hands]
      )

    Enum.map(games, fn game ->
      hands =
        Enum.reduce(game.hands, %{}, fn hand, hands_acc ->
          Map.put(hands_acc, hand.character_id, hand)
        end)

      # Calculate phase_started_at based on game status and timeout duration
      # Hardcoded timeouts for now - technically should be passed in or constants shared?
      # Assuming 60s for betting and 30s for playing

      # FIX: We shouldn't duplicate constants. 
      # Passing timeouts as args?
      # For now, just set to UTC Now if active, assuming full restart of timer.

      phase_started_at =
        case game.status do
          "betting" -> DateTime.utc_now()
          "playing" -> DateTime.utc_now()
          _ -> nil
        end

      # Determine current player ID based on current_player_index
      current_player_id =
        if game.status == "playing" do
          active_hands =
            hands
            |> Map.values()
            |> Enum.filter(fn hand -> hand.status == "playing" end)
            |> Enum.sort_by(fn hand -> hand.position end)

          case Enum.at(active_hands, game.current_player_index) do
            nil ->
              case List.first(active_hands) do
                nil -> nil
                hand -> hand.character_id
              end

            hand ->
              hand.character_id
          end
        else
          nil
        end

      %GameState{
        game: game,
        hands: hands,
        deck: shuffle_deck(),
        phase: String.to_atom(game.status),
        current_player_index: game.current_player_index,
        current_player_id: current_player_id,
        phase_timer: nil,
        phase_started_at: phase_started_at
      }
    end)
  end
end
