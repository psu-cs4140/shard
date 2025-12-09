defmodule Shard.Gambling.BlackjackServer do
  @moduledoc """
  GenServer that manages blackjack games.
  Supports multiple concurrent tables with real-time multiplayer gameplay.
  """
  use GenServer
  require Logger
  import Ecto.Query

  alias Shard.Gambling
  alias Shard.Repo
  alias Shard.Gambling.{BlackjackGame, BlackjackHand}
  alias Phoenix.PubSub

  # Game phases
  @betting_phase_timeout :timer.seconds(30)
  @player_turn_timeout :timer.seconds(15)
  @dealer_turn_delay :timer.seconds(2)

  defmodule GameState do
    @moduledoc false
    defstruct [
      :game,
      :hands,
      :deck,
      :phase,
      :current_player_index,
      :phase_timer,
      :phase_started_at
    ]
  end

  defmodule State do
    @moduledoc false
    defstruct [
      :games  # Map of game_id => GameState
    ]
  end

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Create a new blackjack game table
  """
  def create_game(max_players \\ 6) do
    GenServer.call(__MODULE__, {:create_game, max_players})
  end

  @doc """
  Get game state for a specific game
  """
  def get_game(game_id) do
    GenServer.call(__MODULE__, {:get_game, game_id})
  end

  @doc """
  Join a game at a specific position
  """
  def join_game(game_id, character_id, position) do
    GenServer.call(__MODULE__, {:join_game, game_id, character_id, position})
  end

  @doc """
  Place a bet for a player
  """
  def place_bet(game_id, character_id, amount) do
    GenServer.call(__MODULE__, {:place_bet, game_id, character_id, amount})
  end

  @doc """
  Player hits (takes another card)
  """
  def hit(game_id, character_id) do
    GenServer.call(__MODULE__, {:player_action, game_id, character_id, :hit})
  end

  @doc """
  Player stands (ends their turn)
  """
  def stand(game_id, character_id) do
    GenServer.call(__MODULE__, {:player_action, game_id, character_id, :stand})
  end

  @doc """
  Leave a game
  """
  def leave_game(game_id, character_id) do
    GenServer.call(__MODULE__, {:leave_game, game_id, character_id})
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Load existing games from database
    games = load_existing_games()

    Logger.info("Blackjack server started with #{map_size(games)} existing games")

    state = %State{
      games: games
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:create_game, max_players}, _from, state) do
    game_id = generate_game_id()

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
          deck: shuffle_deck(),
          phase: :waiting,
          current_player_index: 0,
          phase_timer: nil,
          phase_started_at: nil
        }

        new_games = Map.put(state.games, game_id, game_state)

        Logger.info("Created blackjack game #{game_id}")

        # Broadcast game creation
        PubSub.broadcast(
          Shard.PubSub,
          "blackjack:#{game_id}",
          {:game_created, %{game_id: game_id}}
        )

        {:reply, {:ok, game_id}, %{state | games: new_games}}

      {:error, changeset} ->
        Logger.error("Failed to create blackjack game: #{inspect(changeset)}")
        {:reply, {:error, "Failed to create game"}, state}
    end
  end

  @impl true
  def handle_call({:get_game, game_id}, _from, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:reply, {:error, :game_not_found}, state}

      game_state ->
        game_data = %{
          game: game_state.game,
          hands: Map.values(game_state.hands),
          phase: game_state.phase,
          current_player_index: game_state.current_player_index,
          seconds_remaining: seconds_remaining_in_phase(game_state)
        }

        {:reply, {:ok, game_data}, state}
    end
  end

  @impl true
  def handle_call({:join_game, game_id, character_id, position}, _from, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:reply, {:error, :game_not_found}, state}

      game_state ->
        if game_state.phase != :waiting do
          {:reply, {:error, :game_in_progress}, state}
        else
          # Create hand for player
          hand = %BlackjackHand{
            blackjack_game_id: game_state.game.id,
            character_id: character_id,
            position: position,
            hand_cards: [],
            bet_amount: 0,
            status: "betting"
          }

          case Repo.insert(hand) do
            {:ok, saved_hand} ->
              new_hands = Map.put(game_state.hands, character_id, saved_hand)
              new_game_state = %{game_state | hands: new_hands}

              new_games = Map.put(state.games, game_id, new_game_state)

              # Broadcast player joined
              PubSub.broadcast(
                Shard.PubSub,
                "blackjack:#{game_id}",
                {:player_joined, %{character_id: character_id, position: position}}
              )

              {:reply, :ok, %{state | games: new_games}}

            {:error, changeset} ->
              {:reply, {:error, changeset}, state}
          end
        end
    end
  end

  @impl true
  def handle_call({:place_bet, game_id, character_id, amount}, _from, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:reply, {:error, :game_not_found}, state}

      game_state ->
        if game_state.phase != :betting do
          {:reply, {:error, :not_betting_phase}, state}
        else
          case Shard.Gambling.Blackjack.place_bet(game_id, character_id, amount) do
            {:ok, updated_hand} ->
              new_hands = Map.put(game_state.hands, character_id, updated_hand)
              new_game_state = %{game_state | hands: new_hands}

              # Check if all players have placed bets
              all_bets_placed = Enum.all?(new_hands, fn {_id, hand} -> hand.bet_amount > 0 end)

              new_games = Map.put(state.games, game_id, new_game_state)

              if all_bets_placed do
                # Start dealing phase
                {:reply, :ok, start_dealing_phase(game_id, new_games)}
              else
                # Broadcast bet placed
                broadcast_update(game_id, {:bet_placed, %{character_id: character_id, amount: amount}})
                {:reply, :ok, new_games}
              end

            {:error, reason} ->
              {:reply, {:error, reason}, state}
          end
        end
    end
  end

  @impl true
  def handle_call({:player_action, game_id, character_id, action}, _from, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:reply, {:error, :game_not_found}, state}

      game_state ->
        if game_state.phase != :playing do
          {:reply, {:error, :not_playing_phase}, state}
        else
          current_hand = Map.get(game_state.hands, character_id)

          if current_hand && current_hand.status == "playing" do
            case action do
              :hit ->
                {updated_hand, new_deck} = Shard.Gambling.Blackjack.deal_card_to_player(current_hand, game_state.deck)
                {final_hand, new_game_state} = if Shard.Gambling.Blackjack.is_busted?(updated_hand.hand_cards) do
                  # Player busted
                  busted_hand = %{updated_hand | status: "busted"}
                  Shard.Repo.update!(BlackjackHand.changeset(busted_hand, %{status: "busted"}))
                  new_hands = Map.put(game_state.hands, character_id, busted_hand)
                  {busted_hand, %{game_state | hands: new_hands, deck: new_deck}}
                else
                  new_hands = Map.put(game_state.hands, character_id, updated_hand)
                  {updated_hand, %{game_state | hands: new_hands, deck: new_deck}}
                end

                # Broadcast card dealt
                broadcast_update(game_id, {:card_dealt, %{character_id: character_id, card: List.last(final_hand.hand_cards)}})

                if final_hand.status == "busted" do
                  # Move to next player or dealer turn
                  {:reply, :ok, advance_to_next_player_or_dealer(game_id, Map.put(state.games, game_id, new_game_state))}
                else
                  {:reply, :ok, Map.put(state.games, game_id, new_game_state)}
                end

              :stand ->
                # Player stands
                updated_hand = %{current_hand | status: "stood"}
                Shard.Repo.update!(BlackjackHand.changeset(updated_hand, %{status: "stood"}))

                new_hands = Map.put(game_state.hands, character_id, updated_hand)
                new_game_state = %{game_state | hands: new_hands}

                # Broadcast player stood
                broadcast_update(game_id, {:player_stood, %{character_id: character_id}})

                # Move to next player or dealer turn
                new_games = Map.put(state.games, game_id, new_game_state)
                {:reply, :ok, advance_to_next_player_or_dealer(game_id, new_games)}

              _ ->
                {:reply, {:error, :invalid_action}, state}
            end
          else
            {:reply, {:error, :not_your_turn}, state}
          end
        end
    end
  end

  @impl true
  def handle_call({:leave_game, game_id, character_id}, _from, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:reply, {:error, :game_not_found}, state}

      game_state ->
        # Remove player from game
        new_hands = Map.delete(game_state.hands, character_id)
        new_game_state = %{game_state | hands: new_hands}

        # Delete hand from database
        case Shard.Gambling.Blackjack.get_hand(game_id, character_id) do
          nil -> :ok
          hand -> Repo.delete(hand)
        end

        new_games = Map.put(state.games, game_id, new_game_state)

        # Broadcast player left
        broadcast_update(game_id, {:player_left, %{character_id: character_id}})

        {:reply, :ok, new_games}
    end
  end

  # Helper functions

  defp broadcast_update(game_id, message) do
    PubSub.broadcast(
      Shard.PubSub,
      "blackjack:#{game_id}",
      message
    )
  end

  defp start_dealing_phase(game_id, games) do
    game_state = Map.get(games, game_id)

    # Update game status to dealing
    Shard.Gambling.Blackjack.update_game_status(game_id, "dealing")

    # Deal initial cards
    {updated_hands, dealer_cards, remaining_deck} =
      Shard.Gambling.Blackjack.deal_initial_cards(game_state.hands, game_state.deck)

    # Update hands in database
    Enum.each(updated_hands, fn {_id, hand} ->
      Repo.update!(BlackjackHand.changeset(hand, %{hand_cards: hand.hand_cards}))
    end)

    # Update game with dealer hand
    Repo.update!(BlackjackGame.changeset(game_state.game, %{dealer_hand: dealer_cards}))

    # Check for blackjacks
    hands_with_blackjack = Enum.filter(updated_hands, fn {_id, hand} ->
      Shard.Gambling.Blackjack.is_blackjack?(hand.hand_cards)
    end)

    Enum.each(hands_with_blackjack, fn {_id, hand} ->
      Repo.update!(BlackjackHand.changeset(hand, %{status: "blackjack"}))
    end)

    new_game_state = %{
      game_state
      | hands: updated_hands,
        deck: remaining_deck,
        phase: :playing,
        current_player_index: 0,
        phase_started_at: DateTime.utc_now()
    }

    # Broadcast dealing started
    broadcast_update(game_id, {:dealing_started, %{dealer_card: List.first(dealer_cards)}})

    # Start player turns
    start_player_turns(game_id, Map.put(games, game_id, new_game_state))
  end

  defp start_player_turns(game_id, games) do
    game_state = Map.get(games, game_id)

    # Find first active player
    active_players = Enum.filter(game_state.hands, fn {_id, hand} ->
      hand.status in ["playing", "betting"]
    end)

    case active_players do
      [] ->
        # No active players, go to dealer turn
        start_dealer_turn(game_id, games)

      [{character_id, _hand} | _] ->
        # Set current player
        new_game_state = %{game_state | current_player_index: 0}
        broadcast_update(game_id, {:player_turn, %{character_id: character_id}})
        Map.put(games, game_id, new_game_state)
    end
  end

  defp advance_to_next_player_or_dealer(game_id, games) do
    game_state = Map.get(games, game_id)

    # Find next active player
    active_hands = Enum.filter(game_state.hands, fn {_id, hand} ->
      hand.status in ["playing"]
    end)

    case active_hands do
      [] ->
        # No more active players, go to dealer turn
        start_dealer_turn(game_id, games)

      _ ->
        # There are still active players, continue with current game state
        games
    end
  end

  defp start_dealer_turn(game_id, games) do
    game_state = Map.get(games, game_id)

    # Update game status
    Shard.Gambling.Blackjack.update_game_status(game_id, "dealer_turn")

    # Dealer reveals second card and plays
    dealer_final_hand = Shard.Gambling.Blackjack.play_dealer_turn(game_state.game.dealer_hand, game_state.deck)

    # Update dealer hand in database
    Repo.update!(BlackjackGame.changeset(game_state.game, %{dealer_hand: dealer_final_hand}))

    # Process payouts
    Shard.Gambling.Blackjack.process_payouts(game_id, dealer_final_hand)

    # Update game status to finished
    Shard.Gambling.Blackjack.update_game_status(game_id, "finished")

    new_game_state = %{game_state | phase: :finished, game: %{game_state.game | dealer_hand: dealer_final_hand}}

    # Broadcast game finished
    broadcast_update(game_id, {:game_finished, %{dealer_hand: dealer_final_hand}})

    # Schedule game reset after delay
    Process.send_after(self(), {:reset_game, game_id}, :timer.seconds(10))

    Map.put(games, game_id, new_game_state)
  end

  @impl true
  def handle_info({:reset_game, game_id}, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:noreply, state}

      game_state ->
        # Reset game for new round
        reset_game_state = %{
          game_state
          | hands: %{},
            deck: shuffle_deck(),
            phase: :waiting,
            current_player_index: 0,
            phase_timer: nil,
            phase_started_at: nil
        }

        # Update game in database
        Repo.update!(BlackjackGame.changeset(game_state.game, %{
          status: "waiting",
          dealer_hand: [],
          current_player_index: 0
        }))

        new_games = Map.put(state.games, game_id, reset_game_state)

        # Broadcast game reset
        broadcast_update(game_id, {:game_reset, %{}})

        {:noreply, %{state | games: new_games}}
    end
  end

  @impl true
  def handle_info({:phase_timeout, _game_id}, state) do
    # Handle phase timeouts (force stand for current player, etc.)
    {:noreply, state}
  end

  defp load_existing_games do
    # Load games that aren't finished
    games = Repo.all(
      from g in BlackjackGame,
      where: g.status != "finished",
      preload: [:hands]
    )

    Enum.reduce(games, %{}, fn game, acc ->
      hands = Enum.reduce(game.hands, %{}, fn hand, hands_acc ->
        Map.put(hands_acc, hand.character_id, hand)
      end)

      game_state = %GameState{
        game: game,
        hands: hands,
        deck: shuffle_deck(),
        phase: String.to_atom(game.status),
        current_player_index: game.current_player_index,
        phase_timer: nil,
        phase_started_at: nil
      }

      Map.put(acc, game.game_id, game_state)
    end)
  end

  defp shuffle_deck do
    # Create and shuffle a standard 52-card deck
    suits = ["hearts", "diamonds", "clubs", "spades"]
    ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

    deck = for suit <- suits, rank <- ranks do
      %{suit: suit, rank: rank}
    end

    Enum.shuffle(deck)
  end

  defp generate_game_id do
    "blackjack_#{:os.system_time(:millisecond)}_#{:rand.uniform(1000)}"
  end

  defp seconds_remaining_in_phase(game_state) do
    if game_state.phase_started_at do
      # Calculate remaining time based on phase
      timeout = case game_state.phase do
        :betting -> @betting_phase_timeout
        :playing -> @player_turn_timeout
        _ -> 0
      end

      elapsed = DateTime.diff(DateTime.utc_now(), game_state.phase_started_at, :millisecond)
      max(0, div(timeout - elapsed, 1000))
    else
      0
    end
  end
end
