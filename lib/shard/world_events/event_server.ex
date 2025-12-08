defmodule Shard.WorldEvents.EventServer do
  use GenServer
  require Logger

  alias Shard.WorldEvents

  @default_check_interval :timer.minutes(5)  # Check every 5 minutes
  @boss_spawn_chance 0.1  # 10% chance per check

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    # Schedule the first check
    schedule_next_check()
    
    Logger.info("World Events Server started")
    
    {:ok, %{
      check_interval: @default_check_interval,
      last_check: DateTime.utc_now()
    }}
  end

  def handle_info(:check_events, state) do
    # Clean up expired events
    cleanup_expired_events()
    
    # Randomly spawn new events
    maybe_spawn_boss_event()
    
    # Schedule next check
    schedule_next_check()
    
    {:noreply, %{state | last_check: DateTime.utc_now()}}
  end

  def handle_info(msg, state) do
    Logger.warning("Unexpected message in EventServer: #{inspect(msg)}")
    {:noreply, state}
  end

  # Public API
  def force_boss_spawn do
    GenServer.cast(__MODULE__, :force_boss_spawn)
  end

  def get_server_status do
    GenServer.call(__MODULE__, :get_status)
  end

  def handle_cast(:force_boss_spawn, state) do
    case WorldEvents.spawn_random_boss_event() do
      {:ok, event} ->
        Logger.info("Forced boss spawn: #{event.title}")
        broadcast_event_spawn(event)
      {:error, reason} ->
        Logger.warning("Failed to force boss spawn: #{inspect(reason)}")
    end
    
    {:noreply, state}
  end

  def handle_call(:get_status, _from, state) do
    status = %{
      last_check: state.last_check,
      check_interval: state.check_interval,
      active_events_count: length(WorldEvents.get_active_events())
    }
    
    {:reply, status, state}
  end

  # Private functions
  defp schedule_next_check do
    Process.send_after(self(), :check_events, @default_check_interval)
  end

  defp cleanup_expired_events do
    active_events = WorldEvents.get_active_events()
    
    Enum.each(active_events, fn event ->
      unless WorldEvents.WorldEvent.active?(event) do
        case WorldEvents.deactivate_event(event) do
          {:ok, deactivated_event} ->
            Logger.info("Deactivated expired event: #{deactivated_event.title}")
            broadcast_event_end(deactivated_event)
          {:error, reason} ->
            Logger.warning("Failed to deactivate event #{event.id}: #{inspect(reason)}")
        end
      end
    end)
  end

  defp maybe_spawn_boss_event do
    if :rand.uniform() < @boss_spawn_chance do
      case WorldEvents.spawn_random_boss_event() do
        {:ok, event} ->
          Logger.info("Random boss spawned: #{event.title}")
          broadcast_event_spawn(event)
        {:error, reason} ->
          Logger.warning("Failed to spawn random boss: #{inspect(reason)}")
      end
    end
  end

  defp broadcast_event_spawn(event) do
    # Broadcast to all connected players about the new event
    Phoenix.PubSub.broadcast(
      Shard.PubSub,
      "world_events",
      {:world_event_spawned, event}
    )
    
    # If the event is in a specific room, broadcast to that room too
    if event.room_id do
      Phoenix.PubSub.broadcast(
        Shard.PubSub,
        "room:#{event.room_id}",
        {:world_event_spawned, event}
      )
    end
  end

  defp broadcast_event_end(event) do
    # Broadcast to all connected players about the ended event
    Phoenix.PubSub.broadcast(
      Shard.PubSub,
      "world_events",
      {:world_event_ended, event}
    )
    
    # If the event was in a specific room, broadcast to that room too
    if event.room_id do
      Phoenix.PubSub.broadcast(
        Shard.PubSub,
        "room:#{event.room_id}",
        {:world_event_ended, event}
      )
    end
  end
end
