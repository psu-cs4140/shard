defmodule Shard.Gambling.BlackjackServer do
  @moduledoc """
  GenServer that manages blackjack games.
  Supports multiple concurrent tables with real-time multiplayer gameplay.
  """
  use GenServer
  require Logger

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
    # Implementation for placing bets
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:player_action, game_id, character_id, action}, _from, state) do
    # Implementation for player actions (hit/stand)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:leave_game, game_id, character_id}, _from, state) do
    # Implementation for leaving game
    {:reply, :ok, state}
  end

  # Helper functions

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
