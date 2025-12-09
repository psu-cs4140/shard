defmodule Shard.Gambling.BlackjackServer do
  @moduledoc """
  GenServer that manages blackjack games.
  Supports multiple concurrent tables with real-time multiplayer gameplay.
  """
  use GenServer
  require Logger
  import Ecto.Query

  alias Shard.Repo
  alias Shard.Gambling.{BlackjackGame, BlackjackHand}
  alias Phoenix.PubSub

  # Game phases
  @betting_phase_timeout :timer.seconds(30)
  @player_turn_timeout :timer.seconds(15)

  defmodule GameState do
    @moduledoc false
    defstruct [
      :game,
      :hands,
      :deck,
      :phase,
      :current_player_index,
      :current_player_id,
      :phase_timer,
      :phase_started_at
    ]
  end

  defmodule State do
    @moduledoc false
    defstruct [
      # Map of game_id => GameState
      :games
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
  Get the existing blackjack game or create one if it doesn't exist
  """
  def get_or_create_game do
    GenServer.call(__MODULE__, :get_or_create_game)
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

    {:ok, %State{games: games}}
  end

  @impl true
  def handle_call(:get_or_create_game, _from, state) do
    # Find existing blackjack game
    existing_game =
      Repo.one(
        from g in BlackjackGame,
          where: g.status != "finished",
          limit: 1
      )

    if existing_game do
      # Return existing game
      {:reply, {:ok, existing_game.game_id}, state}
    else
      # Create new game
      game_id = "blackjack_main"

      game = %BlackjackGame{
        game_id: game_id,
        status: "waiting",
        dealer_hand: [],
        current_player_index: 0,
        max_players: 6
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

          Logger.info("Created main blackjack game #{game_id}")

          # Broadcast game creation
          PubSub.broadcast(
            Shard.PubSub,
            "blackjack:#{game_id}",
            {:game_created, %{game_id: game_id}}
          )

          {:reply, {:ok, game_id}, %{state | games: new_games}}

        {:error, changeset} ->
          Logger.error("Failed to create main blackjack game: #{inspect(changeset)}")
          {:reply, {:error, "Failed to create game"}, state}
      end
    end
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
        # Load hands with character associations
        hands_with_characters =
          Enum.map(game_state.hands, fn {_character_id, hand} ->
            hand |> Repo.preload(:character)
          end)

        game_data = %{
          game: game_state.game,
          hands: hands_with_characters,
          phase: game_state.phase,
          current_player_index: game_state.current_player_index,
          current_player_id: game_state.current_player_id,
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
        # Check if player is already in the game
        existing_hand = Map.get(game_state.hands, character_id)

        if existing_hand do
          {:reply, {:error, :already_joined}, state}
        else
          # Determine initial status based on current game phase
          initial_status =
            case game_state.phase do
              # Can join and play immediately
              :waiting -> "betting"
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
              new_game_state = %{game_state | hands: new_hands}

              new_games = Map.put(state.games, game_id, new_game_state)

              # If this is the first player joining a waiting game, start it immediately
              updated_games =
                if game_state.phase == :waiting and map_size(new_hands) == 1 do
                  Logger.info("First player joined blackjack game #{game_id}, starting game")
                  start_betting_phase(game_id, new_games)
                else
                  new_games
                end

              # Broadcast player joined
              PubSub.broadcast(
                Shard.PubSub,
                "blackjack:#{game_id}",
                {:player_joined,
                 %{character_id: character_id, position: position, status: initial_status}}
              )

              {:reply, :ok, %{state | games: updated_games}}

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

              new_games = Map.put(state.games, game_id, new_game_state)

              # Broadcast bet placed
              broadcast_update(
                game_id,
                {:bet_placed, %{character_id: character_id, amount: amount}}
              )

              {:reply, :ok, new_games}

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

          if current_hand && current_hand.status == "playing" && game_state.current_player_id == character_id do
            case action do
              :hit ->
                {updated_hand, new_deck} =
                  Shard.Gambling.Blackjack.deal_card_to_player(current_hand, game_state.deck)

                {final_hand, new_game_state} =
                  if Shard.Gambling.Blackjack.is_busted?(updated_hand.hand_cards) do
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
                broadcast_update(
                  game_id,
                  {:card_dealt,
                   %{character_id: character_id, card: List.last(final_hand.hand_cards)}}
                )

                if final_hand.status == "busted" do
                  # Move to next player or dealer turn
                  {:reply, :ok,
                   advance_to_next_player_or_dealer(
                     game_id,
                     Map.put(state.games, game_id, new_game_state)
                   )}
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

  defp start_betting_phase(game_id, games) do
    game_state = Map.get(games, game_id)

    # Update game status to betting
    Shard.Gambling.Blackjack.update_game_status(game_id, "betting")

    now = DateTime.utc_now()

    new_game_state = %{
      game_state
      | phase: :betting,
        phase_started_at: now
    }

    # Schedule phase timeout and countdown ticks
    Process.send_after(__MODULE__, {:phase_timeout, game_id}, @betting_phase_timeout)
    Process.send_after(__MODULE__, {:countdown_tick, game_id}, :timer.seconds(1))

    # Broadcast betting phase started
    broadcast_update(game_id, {:betting_started, %{}})

    Map.put(games, game_id, new_game_state)
  end

  defp start_dealing_phase(game_id, games) do
    game_state = Map.get(games, game_id)

    # Update game status to dealing
    Shard.Gambling.Blackjack.update_game_status(game_id, "dealing")

    # Filter hands to only include players who have placed bets
    active_hands = Map.filter(game_state.hands, fn {_id, hand} -> hand.bet_amount > 0 end)

    # Update status of players who haven't bet to "folded" or similar
    updated_hands =
      Enum.map(game_state.hands, fn {character_id, hand} ->
        if hand.bet_amount == 0 do
          # Player didn't bet, mark as folded
          Repo.update!(BlackjackHand.changeset(hand, %{status: "folded"}))
          {character_id, %{hand | status: "folded"}}
        else
          {character_id, hand}
        end
      end)
      |> Enum.into(%{})

    # Deal initial cards only to active players
    {dealt_hands, dealer_cards, remaining_deck} =
      Shard.Gambling.Blackjack.deal_initial_cards(active_hands, game_state.deck)

    # Merge dealt hands back into all hands
    final_hands = Map.merge(updated_hands, dealt_hands)

    # Update hands in database
    Enum.each(final_hands, fn {_id, hand} ->
      Repo.update!(
        BlackjackHand.changeset(hand, %{hand_cards: hand.hand_cards, status: hand.status})
      )
    end)

    # Update game with dealer hand
    Repo.update!(BlackjackGame.changeset(game_state.game, %{dealer_hand: dealer_cards}))

    # Check for blackjacks among active players
    hands_with_blackjack =
      Enum.filter(dealt_hands, fn {_id, hand} ->
        Shard.Gambling.Blackjack.is_blackjack?(hand.hand_cards)
      end)

    Enum.each(hands_with_blackjack, fn {_id, hand} ->
      Repo.update!(BlackjackHand.changeset(hand, %{status: "blackjack"}))
    end)

    new_game_state = %{
      game_state
      | hands: final_hands,
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

    # Find all active players and sort by position to ensure deterministic order (1-6)
    active_players =
      game_state.hands
      |> Enum.filter(fn {_id, hand} ->
        hand.status in ["playing", "betting"]
      end)
      |> Enum.sort_by(fn {_id, hand} -> hand.position end)

    case active_players do
      [] ->
        # No active players, go to dealer turn
        start_dealer_turn(game_id, games)

      players ->
        # Set first player as current
        [{first_player_id, _hand} | _] = players
        
        now = DateTime.utc_now()

        new_game_state = %{
          game_state
          | current_player_index: 0,
            current_player_id: first_player_id,
            phase_started_at: now
        }

        # Schedule player turn timeout and countdown ticks
        Process.send_after(__MODULE__, {:phase_timeout, game_id}, @player_turn_timeout)
        Process.send_after(__MODULE__, {:countdown_tick, game_id}, :timer.seconds(1))

        # Important: Update all hands to "playing" if they were "betting"
        # This fixes the issue where players might get stuck in "betting" status
        updated_hands = 
          Enum.reduce(game_state.hands, game_state.hands, fn {id, hand}, acc -> 
            if hand.status == "betting" do
               updated = %{hand | status: "playing"}
               # Update DB
               Repo.update!(BlackjackHand.changeset(hand, %{status: "playing"}))
               Map.put(acc, id, updated)
            else
               acc
            end
          end)

        final_game_state = %{new_game_state | hands: updated_hands}

        broadcast_update(game_id, {:player_turn, %{character_id: first_player_id}})
        Map.put(games, game_id, final_game_state)
    end
  end

  defp advance_to_next_player_or_dealer(game_id, games) do
    game_state = Map.get(games, game_id)

    # Get sorted active players again to find who is next
    # We must effectively find the "next" player after the one who just finished
    # But simpler: just find the *first* player in the list who is still "playing"
    # AND hasn't acted yet? No, that's tricky.
    
    # Better approach: We iterate through the sorted positions.
    # The current logic was relying on index, but players might leave.
    
    # Let's find the *next* player relative to the current player's position
    current_player_id = game_state.current_player_id
    current_hand = Map.get(game_state.hands, current_player_id)
    
    current_position = if current_hand, do: current_hand.position, else: 0
    
    # Find next active player with position > current_position
    next_player = 
      game_state.hands
      |> Enum.filter(fn {_id, hand} -> hand.status == "playing" end)
      |> Enum.filter(fn {_id, hand} -> hand.position > current_position end)
      |> Enum.sort_by(fn {_id, hand} -> hand.position end)
      |> List.first()
      
    case next_player do
      nil ->
         # No one left with higher position, start dealer turn
         start_dealer_turn(game_id, games)
         
      {next_id, _hand} ->
         # Found next player
         now = DateTime.utc_now()
         new_game_state = %{
           game_state
           | current_player_id: next_id,
             phase_started_at: now
         }
         
         # Reset timeout
         Process.send_after(__MODULE__, {:phase_timeout, game_id}, @player_turn_timeout)
         
         broadcast_update(game_id, {:player_turn, %{character_id: next_id}})
         Map.put(games, game_id, new_game_state)
    end
  end

  defp start_dealer_turn(game_id, games) do
    game_state = Map.get(games, game_id)

    # Update game status
    Shard.Gambling.Blackjack.update_game_status(game_id, "dealer_turn")

    # Dealer reveals second card and plays
    dealer_final_hand =
      Shard.Gambling.Blackjack.play_dealer_turn(game_state.game.dealer_hand, game_state.deck)

    # Update dealer hand in database
    Repo.update!(BlackjackGame.changeset(game_state.game, %{dealer_hand: dealer_final_hand}))

    # Process payouts
    Shard.Gambling.Blackjack.process_payouts(game_id, dealer_final_hand)

    # Update game status to finished
    Shard.Gambling.Blackjack.update_game_status(game_id, "finished")

    new_game_state = %{
      game_state
      | phase: :finished,
        game: %{game_state.game | dealer_hand: dealer_final_hand}
    }

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
        # Move waiting and folded players to betting status for next round
        updated_hands =
          Enum.map(game_state.hands, fn {character_id, hand} ->
            if hand.status in ["waiting", "folded"] do
              # Update status to betting in database
              Repo.update!(
                BlackjackHand.changeset(hand, %{status: "betting", bet_amount: 0, hand_cards: []})
              )

              # Update status in memory
              {character_id, %{hand | status: "betting", bet_amount: 0, hand_cards: []}}
            else
              {character_id, hand}
            end
          end)
          |> Enum.into(%{})

        # Reset game for new round
        reset_game_state = %{
          game_state
          | hands: updated_hands,
            deck: shuffle_deck(),
            phase: :waiting,
            current_player_index: 0,
            phase_timer: nil,
            phase_started_at: nil
        }

        # Update game in database
        Repo.update!(
          BlackjackGame.changeset(game_state.game, %{
            status: "waiting",
            dealer_hand: [],
            current_player_index: 0
          })
        )

        new_games = Map.put(state.games, game_id, reset_game_state)

        # Broadcast game reset
        broadcast_update(game_id, {:game_reset, %{}})

        {:noreply, %{state | games: new_games}}
    end
  end

  @impl true
  def handle_info({:phase_timeout, game_id}, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:noreply, state}

      game_state ->
        # Handle phase timeouts based on current phase
        case game_state.phase do
          :betting ->
            # Force start dealing if betting timed out
            Logger.info("Betting phase timeout for game #{game_id}, forcing deal")
            new_games = start_dealing_phase(game_id, state.games)
            {:noreply, %{state | games: new_games}}

          :playing ->
            # Force current player to stand
            Logger.info("Player turn timeout for game #{game_id}, forcing stand")

            active_hands =
              Enum.filter(game_state.hands, fn {_id, hand} ->
                hand.status in ["playing"]
              end)

            case active_hands do
              [{character_id, _hand} | _] ->
                # Force stand for current player - call internal logic directly
                current_hand = Map.get(game_state.hands, character_id)

                if current_hand && current_hand.status == "playing" do
                  # Player stands
                  updated_hand = %{current_hand | status: "stood"}
                  Shard.Repo.update!(BlackjackHand.changeset(updated_hand, %{status: "stood"}))

                  new_hands = Map.put(game_state.hands, character_id, updated_hand)
                  new_game_state = %{game_state | hands: new_hands}

                  # Broadcast player stood
                  broadcast_update(game_id, {:player_stood, %{character_id: character_id}})

                  # Move to next player or dealer turn
                  new_games = Map.put(state.games, game_id, new_game_state)
                  updated_games = advance_to_next_player_or_dealer(game_id, new_games)
                  {:noreply, %{state | games: updated_games}}
                else
                  {:noreply, state}
                end

              _ ->
                # No active players, start dealer turn
                new_games = start_dealer_turn(game_id, state.games)
                {:noreply, %{state | games: new_games}}
            end

          _ ->
            {:noreply, state}
        end
    end
  end

  @impl true
  def handle_info({:countdown_tick, game_id}, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:noreply, state}

      game_state ->
        # Broadcast countdown update if phase has a timer
        if game_state.phase in [:betting, :playing] and game_state.phase_started_at do
          seconds_remaining = seconds_remaining_in_phase(game_state)

          if seconds_remaining > 0 do
            # Schedule next tick in 1 second
            Process.send_after(self(), {:countdown_tick, game_id}, :timer.seconds(1))

            # Broadcast countdown update
            broadcast_update(
              game_id,
              {:countdown_update, %{seconds_remaining: seconds_remaining}}
            )
          end
        end

        {:noreply, state}
    end
  end

  defp load_existing_games do
    # Load games that aren't finished
    games =
      Repo.all(
        from g in BlackjackGame,
          where: g.status != "finished",
          preload: [:hands]
      )

    Enum.reduce(games, %{}, fn game, acc ->
      hands =
        Enum.reduce(game.hands, %{}, fn hand, hands_acc ->
          Map.put(hands_acc, hand.character_id, hand)
        end)

      # Calculate phase_started_at based on game status and timeout duration
      phase_started_at =
        case game.status do
          "betting" ->
            DateTime.add(
              DateTime.utc_now(),
              -(@betting_phase_timeout - @betting_phase_timeout),
              :millisecond
            )

          "playing" ->
            DateTime.add(
              DateTime.utc_now(),
              -(@player_turn_timeout - @player_turn_timeout),
              :millisecond
            )

          _ ->
            nil
        end

      game_state = %GameState{
        game: game,
        hands: hands,
        deck: shuffle_deck(),
        phase: String.to_atom(game.status),
        current_player_index: game.current_player_index,
        phase_timer: nil,
        phase_started_at: phase_started_at
      }

      # Restart timers for active games
      game_state = restart_timers_if_needed(game.game_id, game_state)

      Map.put(acc, game.game_id, game_state)
    end)
  end

  defp shuffle_deck do
    # Create and shuffle a standard 52-card deck
    suits = ["hearts", "diamonds", "clubs", "spades"]
    ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

    deck =
      for suit <- suits, rank <- ranks do
        %{suit: suit, rank: rank}
      end

    Enum.shuffle(deck)
  end

  defp generate_game_id do
    "blackjack_#{:os.system_time(:millisecond)}_#{:rand.uniform(1000)}"
  end

  defp restart_timers_if_needed(game_id, game_state) do
    case game_state.phase do
      :betting ->
        # Restart betting phase timers
        Process.send_after(__MODULE__, {:phase_timeout, game_id}, @betting_phase_timeout)
        Process.send_after(__MODULE__, {:countdown_tick, game_id}, :timer.seconds(1))
        game_state

      :playing ->
        # Restart playing phase timers
        Process.send_after(__MODULE__, {:phase_timeout, game_id}, @player_turn_timeout)
        Process.send_after(__MODULE__, {:countdown_tick, game_id}, :timer.seconds(1))
        game_state

      _ ->
        game_state
    end
  end

  defp seconds_remaining_in_phase(game_state) do
    if game_state.phase_started_at do
      # Calculate remaining time based on phase
      timeout =
        case game_state.phase do
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
