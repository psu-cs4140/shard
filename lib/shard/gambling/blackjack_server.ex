defmodule Shard.Gambling.BlackjackServer do
  @moduledoc """
  GenServer that manages blackjack games.
  Supports multiple concurrent tables with real-time multiplayer gameplay.
  """
  use GenServer
  require Logger
  import Ecto.Query

  alias Shard.Repo
  alias Shard.Gambling.BlackjackGame
  alias Shard.Gambling.Blackjack.Actions
  alias Phoenix.PubSub

  # Game phases
  @betting_phase_timeout :timer.seconds(30)
  @player_turn_timeout :timer.seconds(15)

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
      game_id = generate_game_id()

      case Actions.create_game_state(game_id, 6) do
        {:ok, game_state} ->
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

    case Actions.create_game_state(game_id, max_players) do
      {:ok, game_state} ->
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
        case Actions.join_game(game_id, character_id, position, game_state) do
          {:ok, %{hands: new_hands, initial_status: initial_status}} ->
            new_game_state = %{game_state | hands: new_hands}
            new_games = Map.put(state.games, game_id, new_game_state)

            # If first player, start game
            final_games =
              if game_state.phase == :waiting and map_size(new_hands) == 1 do
                Logger.info("First player joined blackjack game #{game_id}, starting game")
                start_betting_phase(game_id, new_games)
              else
                new_games
              end

            # Broadcast
            PubSub.broadcast(
              Shard.PubSub,
              "blackjack:#{game_id}",
              {:player_joined,
               %{character_id: character_id, position: position, status: initial_status}}
            )

            {:reply, :ok, %{state | games: final_games}}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
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

              {:reply, :ok, %{state | games: new_games}}

            {:error, reason} ->
              {:reply, {:error, reason}, state}
          end
        end
    end
  end

  @impl true
  def handle_call({:player_action, game_id, character_id, action}, _from, state) do
    do_handle_player_action(game_id, character_id, action, state)
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

        {:reply, :ok, %{state | games: new_games}}
    end
  end

  # Helper functions

  defp process_hit(game_id, character_id, _current_hand, game_state, state) do
    current_hand = Map.get(game_state.hands, character_id)

    # Delegate logic to Actions
    {outcome, updated_hand, new_deck} = Actions.hit(character_id, current_hand, game_state.deck)

    # Update state
    new_hands = Map.put(game_state.hands, character_id, updated_hand)
    new_game_state = %{game_state | hands: new_hands, deck: new_deck}

    # Broadcast
    broadcast_update(
      game_id,
      {:card_dealt, %{character_id: character_id, card: List.last(updated_hand.hand_cards)}}
    )

    if outcome == :busted do
      # Advance
      {:reply, :ok,
       %{
         state
         | games:
             advance_to_next_player_or_dealer(
               game_id,
               Map.put(state.games, game_id, new_game_state)
             )
       }}
    else
      {:reply, :ok, %{state | games: Map.put(state.games, game_id, new_game_state)}}
    end
  end

  defp process_stand(game_id, character_id, current_hand, game_state, state) do
    updated_hand = Actions.stand(character_id, current_hand)

    new_hands = Map.put(game_state.hands, character_id, updated_hand)
    new_game_state = %{game_state | hands: new_hands}

    # Broadcast player stood
    broadcast_update(game_id, {:player_stood, %{character_id: character_id}})

    # Move to next player or dealer turn
    new_games = Map.put(state.games, game_id, new_game_state)

    {:reply, :ok, %{state | games: advance_to_next_player_or_dealer(game_id, new_games)}}
  end

  defp do_handle_player_action(game_id, character_id, action, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:reply, {:error, :game_not_found}, state}

      game_state ->
        validate_and_process_action(game_state, game_id, character_id, action, state)
    end
  end

  defp validate_and_process_action(
         %{phase: :playing} = game_state,
         game_id,
         character_id,
         action,
         state
       ) do
    current_hand = Map.get(game_state.hands, character_id)

    if current_hand && current_hand.status == "playing" &&
         game_state.current_player_id == character_id do
      case action do
        :hit -> process_hit(game_id, character_id, current_hand, game_state, state)
        :stand -> process_stand(game_id, character_id, current_hand, game_state, state)
        _ -> {:reply, {:error, :invalid_action}, state}
      end
    else
      {:reply, {:error, :not_your_turn}, state}
    end
  end

  defp validate_and_process_action(_game_state, _game_id, _cid, _action, state) do
    {:reply, {:error, :not_playing_phase}, state}
  end

  defp broadcast_update(game_id, message) do
    PubSub.broadcast(
      Shard.PubSub,
      "blackjack:#{game_id}",
      message
    )
  end

  defp dispatch_actions(game_id, actions) do
    Enum.each(actions, fn
      {:broadcast, msg} -> broadcast_update(game_id, msg)
      {:schedule, msg, time} -> Process.send_after(__MODULE__, msg, time)
    end)
  end

  defp start_betting_phase(game_id, games) do
    {:ok, new_game_state, actions} = Actions.start_betting_phase(game_id, Map.get(games, game_id))
    dispatch_actions(game_id, actions)
    Map.put(games, game_id, new_game_state)
  end

  defp start_dealing_phase(game_id, games) do
    {:ok, new_game_state, actions} = Actions.start_dealing_phase(game_id, Map.get(games, game_id))
    dispatch_actions(game_id, actions)
    Map.put(games, game_id, new_game_state)
  end

  defp start_player_turns(game_id, games) do
    case Actions.start_player_turns(game_id, Map.get(games, game_id)) do
      {:ok, new_game_state, actions} ->
        dispatch_actions(game_id, actions)
        Map.put(games, game_id, new_game_state)
    end
  end

  defp advance_to_next_player_or_dealer(game_id, games) do
    {:ok, new_game_state, actions} =
      Actions.advance_to_next_player_or_dealer(game_id, Map.get(games, game_id))

    dispatch_actions(game_id, actions)
    Map.put(games, game_id, new_game_state)
  end

  defp start_dealer_turn(game_id, games) do
    {:ok, new_game_state, actions} = Actions.start_dealer_turn(game_id, Map.get(games, game_id))
    dispatch_actions(game_id, actions)
    Map.put(games, game_id, new_game_state)
  end

  # Handle sequential dealing
  @impl true
  def handle_info({:deal_next, game_id}, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:noreply, state}

      _ ->
        case Actions.deal_next_card(game_id, Map.get(state.games, game_id)) do
          {:finished, _game_state} ->
            {:noreply, %{state | games: start_player_turns(game_id, state.games)}}

          {:continue, event, updated_game_state, delay} ->
            broadcast_update(game_id, event)
            Process.send_after(__MODULE__, {:deal_next, game_id}, delay)
            {:noreply, %{state | games: Map.put(state.games, game_id, updated_game_state)}}
        end
    end
  end

  @impl true
  def handle_info({:reset_game, game_id}, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:noreply, state}

      game_state ->
        {updated_game, updated_hands} =
          Actions.reset_game_for_new_round(game_id, game_state.hands, game_state.game)

        # Reset game for new round
        reset_game_state = %{
          game_state
          | game: updated_game,
            hands: updated_hands,
            deck: Shard.Gambling.Blackjack.shuffle_deck(),
            phase: :waiting,
            current_player_index: 0,
            phase_timer: nil,
            phase_started_at: nil
        }

        new_games = Map.put(state.games, game_id, reset_game_state)

        # Broadcast game reset
        broadcast_update(game_id, {:game_reset, %{}})

        # If there are players, start betting phase immediately
        final_games =
          if map_size(updated_hands) > 0 do
            Logger.info("Restarting game #{game_id} with #{map_size(updated_hands)} players")
            start_betting_phase(game_id, new_games)
          else
            new_games
          end

        {:noreply, %{state | games: final_games}}
    end
  end

  @impl true
  def handle_info({:phase_timeout, game_id, phase_ref}, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:noreply, state}

      game_state ->
        case Actions.resolve_phase_timeout(game_id, game_state, phase_ref, state.games) do
          {:timeout_action, :start_dealing} ->
            new_games = start_dealing_phase(game_id, state.games)
            {:noreply, %{state | games: new_games}}

          {:timeout_action, {:player_stood, character_id, _new_hands}} ->
            # Broadcast and advance
            broadcast_update(game_id, {:player_stood, %{character_id: character_id}})

            # Note: Actions.resolve_phase_timeout returned new hands but we need to put it into state
            # Wait, resolve_phase_timeout returned {:player_stood, cid, new_hands} but didn't return the full game state struct?
            # Actually I made it return just the action description. 
            # I should update state locally because I have the logic here mostly wrapped in advance_...
            # But wait, Actions.stand ALREADY updated the DB. 
            # Let's just create the state update here.

            current_hand = Map.get(game_state.hands, character_id)
            updated_hand = %{current_hand | status: "stood"}
            new_hands = Map.put(game_state.hands, character_id, updated_hand)
            new_game_state = %{game_state | hands: new_hands}

            new_games = Map.put(state.games, game_id, new_game_state)
            updated_games = advance_to_next_player_or_dealer(game_id, new_games)
            {:noreply, %{state | games: updated_games}}

          {:timeout_action, :start_dealer_turn} ->
            new_games = start_dealer_turn(game_id, state.games)
            {:noreply, %{state | games: new_games}}

          :ignore ->
            {:noreply, state}
        end
    end
  end

  @impl true
  def handle_info({:phase_timeout, game_id}, state) do
    # Legacy fallback: Treat as valid but log warning.
    # To be safe for tests that might rely on this.
    Logger.warning("Received legacy phase_timeout for game #{game_id}")
    {:noreply, state}
  end

  # Keep legacy handler for backward compatibility during hot upgrade if needed, or remove.
  # But we'll replace it.

  @impl true
  def handle_info({:countdown_tick, game_id, phase_ref}, state) do
    case Map.get(state.games, game_id) do
      nil ->
        {:noreply, state}

      game_state ->
        # Broadcast countdown update if phase has a timer AND ref matches
        if game_state.phase_ref == phase_ref and game_state.phase in [:betting, :playing] and
             game_state.phase_started_at do
          seconds_remaining = seconds_remaining_in_phase(game_state)

          if seconds_remaining > 0 do
            # Schedule next tick in 1 second with same ref
            Process.send_after(self(), {:countdown_tick, game_id, phase_ref}, :timer.seconds(1))

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

  @impl true
  def handle_info({:countdown_tick, _game_id}, state) do
    # Legacy fallback: Ignore old countdown checks
    {:noreply, state}
  end

  defp load_existing_games do
    # Restore games from DB via Context
    games = Shard.Gambling.Blackjack.restore_active_games()

    # Iterate and restart timers for each
    Enum.reduce(games, %{}, fn game_state, acc ->
      # Restart timers for active games
      updated_state = restart_timers_if_needed(game_state.game.game_id, game_state)
      Map.put(acc, game_state.game.game_id, updated_state)
    end)
  end

  defp generate_game_id do
    "blackjack_#{:os.system_time(:millisecond)}_#{:rand.uniform(1000)}"
  end

  defp restart_timers_if_needed(game_id, game_state) do
    # Generate new phase reference for restarted timer
    phase_ref = make_ref()

    updated_state = %{game_state | phase_ref: phase_ref}

    case game_state.phase do
      :betting ->
        # Restart betting phase timers
        Process.send_after(
          __MODULE__,
          {:phase_timeout, game_id, phase_ref},
          @betting_phase_timeout
        )

        Process.send_after(__MODULE__, {:countdown_tick, game_id, phase_ref}, :timer.seconds(1))
        updated_state

      :playing ->
        # Restart playing phase timers
        Process.send_after(__MODULE__, {:phase_timeout, game_id, phase_ref}, @player_turn_timeout)
        Process.send_after(__MODULE__, {:countdown_tick, game_id, phase_ref}, :timer.seconds(1))
        updated_state

      _ ->
        updated_state
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
