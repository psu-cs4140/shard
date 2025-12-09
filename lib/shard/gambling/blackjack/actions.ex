defmodule Shard.Gambling.Blackjack.Actions do
  @moduledoc """
  Module containing pure game logic and DB updates for Blackjack actions.
  """

  alias Shard.Repo
  alias Shard.Gambling.{BlackjackGame, BlackjackHand, Blackjack}
  alias Shard.Gambling.Blackjack.GameState

  require Logger

  # Game constants
  @betting_phase_timeout :timer.seconds(30)
  @player_turn_timeout :timer.seconds(15)

  @doc """
  Handle a player joining the game.
  """
  def join_game(_game_id, character_id, position, game_state) do
    # Check if player is already in the game
    existing_hand = Map.get(game_state.hands, character_id)

    if existing_hand do
      {:error, :already_joined}
    else
      # Determine initial status based on current game phase
      initial_status =
        case game_state.phase do
          # Can join and play immediately
          :waiting -> "betting"
          :betting -> "betting"
          # Joined mid-game, wait for next round
          _ -> "waiting"
        end

      # Create hand for player
      hand = %BlackjackHand{
        blackjack_game_id: game_state.game.id,
        character_id: character_id,
        position: position,
        hand_cards: [],
        bet_amount: 0,
        status: initial_status
      }

      case Repo.insert(hand) do
        {:ok, saved_hand} ->
          new_hands = Map.put(game_state.hands, character_id, saved_hand)

          # Return updated game state pieces and event info, NOT the full GameState struct to avoid circular deps if possible,
          # but here we take game_state as input, so returning fields is fine.

          {:ok,
           %{
             hands: new_hands,
             initial_status: initial_status
           }}

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  @doc """
  Process a player HIT action.
  Returns {outcome_type, updated_hand, new_deck}
  outcome_type: :continue | :busted
  """
  def hit(_character_id, current_hand, deck) do
    {updated_hand, new_deck} =
      Blackjack.deal_card_to_player(current_hand, deck)

    if Blackjack.is_busted?(updated_hand.hand_cards) do
      # Player busted
      busted_hand = %{updated_hand | status: "busted"}

      # Update status AND hand_cards to DB
      Repo.update!(
        BlackjackHand.changeset(busted_hand, %{
          status: "busted",
          hand_cards: busted_hand.hand_cards
        })
      )

      {:busted, busted_hand, new_deck}
    else
      # Save updated hand with new card to DB
      Repo.update!(BlackjackHand.changeset(updated_hand, %{hand_cards: updated_hand.hand_cards}))

      {:continue, updated_hand, new_deck}
    end
  end

  @doc """
  Process a player STAND action.
  Returns updated_hand.
  """
  def stand(_character_id, current_hand) do
    updated_hand = %{current_hand | status: "stood"}
    Repo.update!(BlackjackHand.changeset(updated_hand, %{status: "stood"}))
    updated_hand
  end

  #
  # PHASE TRANSITIONS (Moved from Blackjack.ex)
  #

  @doc """
  Initialize the dealing phase.
  """
  def initiate_dealing_phase(game_id, hands) do
    # Update game status via DB helper
    Blackjack.update_game_status(game_id, "dealing")

    # Filter hands to only include players who have placed bets
    active_hands = Map.filter(hands, fn {_id, hand} -> hand.bet_amount > 0 end)

    # Update status of players who haven't bet to "folded"
    updated_hands =
      Enum.map(hands, fn {character_id, hand} ->
        if hand.bet_amount == 0 do
          Repo.update!(BlackjackHand.changeset(hand, %{status: "folded"}))
          {character_id, %{hand | status: "folded"}}
        else
          {character_id, hand}
        end
      end)
      |> Enum.into(%{})

    # Sort active hands by position
    sorted_active_hands =
      active_hands
      |> Enum.sort_by(fn {_id, hand} -> hand.position end)

    # Prepare dealing queue: 2 rounds
    # Round 1: All players (face up), then Dealer (face up)
    # Round 2: All players (face up), then Dealer (face down)
    player_ids = Enum.map(sorted_active_hands, fn {id, _} -> {id, :face_up} end)

    queue =
      player_ids ++
        [{:dealer, :face_up}] ++
        player_ids ++ [{:dealer, :face_down}]

    {queue, updated_hands}
  end

  @doc """
  Initialize player turns.
  """
  def initiate_player_turns(game_id, hands) do
    # Find active players
    active_players =
      hands
      |> Enum.filter(fn {_id, hand} ->
        hand.status in ["playing", "betting"]
      end)
      |> Enum.sort_by(fn {_id, hand} -> hand.position end)

    case active_players do
      [] ->
        {:empty}

      players ->
        [{first_player_id, _hand} | _] = players

        # Update game status to playing
        Blackjack.update_game_status(game_id, "playing")

        # Update all active hands to "playing" if they were "betting"
        updated_hands =
          Enum.reduce(hands, hands, fn {id, hand}, acc ->
            if hand.status == "betting" do
              updated = %{hand | status: "playing"}
              Repo.update!(BlackjackHand.changeset(hand, %{status: "playing"}))
              Map.put(acc, id, updated)
            else
              acc
            end
          end)

        {:ok, first_player_id, updated_hands}
    end
  end

  @doc """
  Find the next player in the turn order.
  """
  def find_next_player(hands, current_player_id) do
    current_hand = Map.get(hands, current_player_id)
    current_position = if current_hand, do: current_hand.position, else: 0

    hands
    |> Enum.filter(fn {_id, hand} -> hand.status == "playing" end)
    |> Enum.filter(fn {_id, hand} -> hand.position > current_position end)
    |> Enum.sort_by(fn {_id, hand} -> hand.position end)
    |> List.first()
  end

  @doc """
  Execute the dealer's turn.
  """
  def execute_dealer_turn(game_id, dealer_hand, deck, game_struct) do
    Blackjack.update_game_status(game_id, "dealer_turn")

    # Dealer plays
    dealer_final_hand = Blackjack.play_dealer_turn(dealer_hand, deck)

    # Update dealer hand in database
    Repo.update!(BlackjackGame.changeset(game_struct, %{dealer_hand: dealer_final_hand}))

    # Process payouts
    Blackjack.process_payouts(game_id, dealer_final_hand)

    # Reload hands to get computed outcomes
    updated_hands =
      Blackjack.get_game_hands(game_id)
      |> Enum.map(fn hand -> {hand.character_id, hand} end)
      |> Enum.into(%{})

    Blackjack.update_game_status(game_id, "finished")

    {dealer_final_hand, updated_hands}
  end

  @doc """
  Reset game for new round.
  """
  def reset_game_for_new_round(_game_id, hands, game_struct) do
    # Reset all hands to betting status
    updated_hands =
      Enum.map(hands, fn {character_id, hand} ->
        # Reset hand data
        reset_hand_attrs = %{
          status: "betting",
          bet_amount: 0,
          hand_cards: [],
          outcome: "pending",
          payout: 0
        }

        try do
          Repo.update!(BlackjackHand.changeset(hand, reset_hand_attrs))
          {character_id, Map.merge(hand, reset_hand_attrs)}
        rescue
          Ecto.StaleEntryError ->
            # Hand no longer exists, filter it out
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})

    # Update game in database
    updated_game =
      Repo.update!(
        BlackjackGame.changeset(game_struct, %{
          status: "waiting",
          dealer_hand: [],
          current_player_index: 0
        })
      )

    {updated_game, updated_hands}
  end

  @doc """
  Create a new game state.
  """
  def create_game_state(game_id, max_players) do
    game = %BlackjackGame{
      game_id: game_id,
      status: "waiting",
      dealer_hand: [],
      current_player_index: 0,
      max_players: max_players
    }

    case Repo.insert(game) do
      {:ok, saved_game} ->
        game_state = %GameState{
          game: saved_game,
          hands: %{},
          deck: Blackjack.shuffle_deck(),
          phase: :waiting,
          current_player_index: 0,
          phase_timer: nil,
          phase_started_at: nil
        }

        {:ok, game_state}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Deal the next card in the queue.
  Returns {:ok, event, updated_game_state, NextStep}
  NextStep: {:continue, delay_ms} | {:finished}
  """
  def deal_next_card(_game_id, game_state) do
    case game_state.dealing_queue do
      [] ->
        {:finished, game_state}

      [next_target | rest_queue] ->
        {target_id, visibility} = next_target
        [card | remaining_deck] = game_state.deck

        {updated_game_inner, event} =
          case target_id do
            :dealer ->
              # Update dealer hand
              current_hand = game_state.game.dealer_hand
              new_hand = current_hand ++ [card]

              Repo.update!(BlackjackGame.changeset(game_state.game, %{dealer_hand: new_hand}))

              masked_card =
                if visibility == :face_down, do: %{rank: "hidden", suit: "hidden"}, else: card

              updated_gs = %{
                game_state
                | deck: remaining_deck,
                  dealing_queue: rest_queue,
                  game: %{game_state.game | dealer_hand: new_hand}
              }

              {updated_gs, {:card_dealt, %{target: :dealer, card: masked_card}}}

            player_id ->
              # Update player hand
              current_hand = Map.get(game_state.hands, player_id)
              new_hand_cards = current_hand.hand_cards ++ [card]

              Repo.update!(BlackjackHand.changeset(current_hand, %{hand_cards: new_hand_cards}))

              updated_hands =
                Map.put(
                  game_state.hands,
                  player_id,
                  %{current_hand | hand_cards: new_hand_cards}
                )

              updated_gs = %{
                game_state
                | deck: remaining_deck,
                  dealing_queue: rest_queue,
                  hands: updated_hands
              }

              {updated_gs, {:card_dealt, %{target: player_id, card: card}}}
          end

        {:continue, event, updated_game_inner, 800}
    end
  end

  @doc """
  Resolve phase timeout.
  Returns {:ok, new_game_state, transition_action} | :ignore
  transition_action: :start_dealing | {:force_stand, updated_games_map} | :start_dealer_turn
  """
  def resolve_phase_timeout(game_id, game_state, phase_ref, _server_state_games) do
    if game_state.phase_ref == phase_ref do
      case game_state.phase do
        :betting ->
          Logger.info("Betting phase timeout for game #{game_id}, forcing deal")
          {:timeout_action, :start_dealing}

        :playing ->
          Logger.info("Player turn timeout for game #{game_id}, forcing stand")

          # Force stand logic
          case find_active_player(game_state.hands) do
            {character_id, current_hand} ->
              # Pass full games map if we need to update it externally, 
              # but ideally we just return operation instructions.
              # Let's return the stand update.

              updated_hand = stand(character_id, current_hand)
              new_hands = Map.put(game_state.hands, character_id, updated_hand)

              {:timeout_action, {:player_stood, character_id, new_hands}}

            nil ->
              {:timeout_action, :start_dealer_turn}
          end

        _ ->
          :ignore
      end
    else
      :ignore
    end
  end

  defp find_active_player(hands) do
    Enum.find(hands, fn {_id, hand} -> hand.status == "playing" end)
  end

  @doc """
  Start betting phase.
  Returns {:ok, new_game_state, actions}
  actions: list of {:broadcast, msg} | {:schedule, msg, time}
  """
  def start_betting_phase(game_id, game_state) do
    # Generate new phase reference
    phase_ref = make_ref()
    now = DateTime.utc_now()

    # Update game status
    Blackjack.update_game_status(game_id, "betting")

    new_game_state = %{
      game_state
      | phase: :betting,
        phase_started_at: now,
        phase_ref: phase_ref
    }

    actions = [
      {:schedule, {:phase_timeout, game_id, phase_ref}, @betting_phase_timeout},
      {:schedule, {:countdown_tick, game_id, phase_ref}, :timer.seconds(1)},
      {:broadcast, {:betting_started, %{seconds_remaining: @betting_phase_timeout / 1000}}}
    ]

    {:ok, new_game_state, actions}
  end

  @doc """
  Start dealing phase.
  """
  def start_dealing_phase(game_id, game_state) do
    {queue, updated_hands} = initiate_dealing_phase(game_id, game_state.hands)

    new_game_state = %{
      game_state
      | phase: :dealing,
        dealing_queue: queue,
        hands: Map.merge(game_state.hands, updated_hands)
    }

    actions = [
      {:broadcast, {:dealing_started, %{}}},
      {:schedule, {:deal_next, game_id}, 500}
    ]

    {:ok, new_game_state, actions}
  end

  @doc """
  Start player turns.
  """
  def start_player_turns(game_id, game_state) do
    case initiate_player_turns(game_id, game_state.hands) do
      {:empty} ->
        # No active players, go to dealer turn
        start_dealer_turn(game_id, game_state)

      {:ok, first_player_id, updated_hands} ->
        now = DateTime.utc_now()
        phase_ref = make_ref()

        new_game_state = %{
          game_state
          | phase: :playing,
            current_player_index: 0,
            current_player_id: first_player_id,
            phase_started_at: now,
            phase_ref: phase_ref,
            hands: updated_hands
        }

        actions = [
          {:schedule, {:phase_timeout, game_id, phase_ref}, @player_turn_timeout},
          {:schedule, {:countdown_tick, game_id, phase_ref}, :timer.seconds(1)},
          {:broadcast, {:player_turn, %{character_id: first_player_id}}}
        ]

        {:ok, new_game_state, actions}
    end
  end

  @doc """
  Advance to next player or dealer.
  """
  def advance_to_next_player_or_dealer(game_id, game_state) do
    next_player = find_next_player(game_state.hands, game_state.current_player_id)

    case next_player do
      nil ->
        # No one left, start dealer turn
        start_dealer_turn(game_id, game_state)

      {next_id, _hand} ->
        now = DateTime.utc_now()
        phase_ref = make_ref()

        new_game_state = %{
          game_state
          | current_player_id: next_id,
            phase_started_at: now,
            phase_ref: phase_ref
        }

        actions = [
          {:schedule, {:phase_timeout, game_id, phase_ref}, @player_turn_timeout},
          {:schedule, {:countdown_tick, game_id, phase_ref}, :timer.seconds(1)},
          {:broadcast, {:player_turn, %{character_id: next_id}}}
        ]

        {:ok, new_game_state, actions}
    end
  end

  @doc """
  Start dealer turn.
  """
  def start_dealer_turn(game_id, game_state) do
    {dealer_final_hand, updated_hands} =
      execute_dealer_turn(game_id, game_state.game.dealer_hand, game_state.deck, game_state.game)

    new_game_state = %{
      game_state
      | phase: :finished,
        hands: updated_hands,
        game: %{game_state.game | dealer_hand: dealer_final_hand}
    }

    actions = [
      {:broadcast, {:game_finished, %{dealer_hand: dealer_final_hand}}},
      {:schedule, {:reset_game, game_id}, :timer.seconds(10)}
    ]

    {:ok, new_game_state, actions}
  end
end
