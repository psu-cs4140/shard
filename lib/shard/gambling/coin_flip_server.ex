defmodule Shard.Gambling.CoinFlipServer do
  @moduledoc """
  GenServer that manages timed coin flip events.
  A coin flip happens every 30 seconds and all players bet on the same flip.
  """
  use GenServer
  require Logger

  alias Shard.Gambling
  alias Phoenix.PubSub

  @flip_interval :timer.seconds(30)
  @countdown_interval :timer.seconds(1)

  defmodule State do
    @moduledoc false
    defstruct [
      :flip_id,
      :next_flip_at,
      :countdown_timer,
      :flip_timer
    ]
  end

  # Client API

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Get the current flip information
  """
  def get_current_flip do
    GenServer.call(__MODULE__, :get_current_flip)
  end

  @doc """
  Get seconds until next flip
  """
  def seconds_until_flip do
    GenServer.call(__MODULE__, :seconds_until_flip)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Start the first flip immediately on startup
    next_flip_at = DateTime.add(DateTime.utc_now(), 30, :second)
    flip_id = generate_flip_id()

    # Schedule the flip
    flip_timer = Process.send_after(self(), :execute_flip, @flip_interval)

    # Start countdown broadcasts
    countdown_timer = Process.send_after(self(), :broadcast_countdown, @countdown_interval)

    Logger.info("CoinFlip server started. Next flip at #{next_flip_at}")

    state = %State{
      flip_id: flip_id,
      next_flip_at: next_flip_at,
      countdown_timer: countdown_timer,
      flip_timer: flip_timer
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:get_current_flip, _from, state) do
    flip_info = %{
      flip_id: state.flip_id,
      next_flip_at: state.next_flip_at
    }

    {:reply, flip_info, state}
  end

  @impl true
  def handle_call(:seconds_until_flip, _from, state) do
    now = DateTime.utc_now()
    seconds = DateTime.diff(state.next_flip_at, now)
    {:reply, max(0, seconds), state}
  end

  @impl true
  def handle_info(:execute_flip, state) do
    # Execute the coin flip
    result = flip_coin()

    Logger.info("Executing coin flip #{state.flip_id}. Result: #{result}")

    # Process all bets for this flip
    case Gambling.process_flip_results(state.flip_id, result) do
      {:ok, stats} ->
        Logger.info(
          "Processed #{stats.total_bets} bets. Winners: #{stats.winners}, Losers: #{stats.losers}"
        )

        # Broadcast the result to all connected clients
        PubSub.broadcast(
          Shard.PubSub,
          "coin_flip",
          {:flip_result, %{flip_id: state.flip_id, result: result, stats: stats}}
        )

      {:error, reason} ->
        Logger.error("Failed to process flip results: #{inspect(reason)}")
    end

    # Schedule next flip
    next_flip_at = DateTime.add(DateTime.utc_now(), 30, :second)
    new_flip_id = generate_flip_id()
    flip_timer = Process.send_after(self(), :execute_flip, @flip_interval)

    Logger.info("Next flip #{new_flip_id} scheduled at #{next_flip_at}")

    # Broadcast new flip started
    PubSub.broadcast(
      Shard.PubSub,
      "coin_flip",
      {:new_flip, %{flip_id: new_flip_id, next_flip_at: next_flip_at}}
    )

    new_state = %{
      state
      | flip_id: new_flip_id,
        next_flip_at: next_flip_at,
        flip_timer: flip_timer
    }

    {:noreply, new_state}
  end

  @impl true
  def handle_info(:broadcast_countdown, state) do
    now = DateTime.utc_now()
    seconds_remaining = DateTime.diff(state.next_flip_at, now)

    # Broadcast countdown update
    PubSub.broadcast(
      Shard.PubSub,
      "coin_flip",
      {:countdown_update, %{seconds_remaining: max(0, seconds_remaining)}}
    )

    # Schedule next countdown broadcast
    countdown_timer = Process.send_after(self(), :broadcast_countdown, @countdown_interval)

    {:noreply, %{state | countdown_timer: countdown_timer}}
  end

  # Private helpers

  defp flip_coin do
    if :rand.uniform(2) == 1, do: "heads", else: "tails"
  end

  defp generate_flip_id do
    "flip_#{:os.system_time(:millisecond)}"
  end
end
