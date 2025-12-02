defmodule Shard.Combat.Server do
  @moduledoc false
  use GenServer

  @tick_ms 1000

  def start_link(opts),
    do: GenServer.start_link(__MODULE__, opts, name: via(opts[:combat_id]))

  def via(id),
    do: {:via, Registry, {Shard.Registry, {:combat, id}}}

  def init(opts) do
    state =
      opts
      |> Map.new()
      |> Map.put_new(:tick_seq, 0)
      |> Map.put_new(:events, [])

    :timer.send_interval(@tick_ms, :tick)
    {:ok, state}
  end

  def handle_info(:tick, state) do
    state1 = Map.put_new(state, :events, [])

    result =
      if Code.ensure_loaded?(Shard.Combat.Engine) and
           function_exported?(Shard.Combat.Engine, :step, 1) do
        apply(Shard.Combat.Engine, :step, [state1])
      else
        {:ok, state1, state1[:events] || []}
      end

    case result do
      {:ok, s2, events} ->
        # Broadcast events to all players in this combat
        broadcast_combat_events(s2, events)
        {:noreply, %{s2 | tick_seq: (s2[:tick_seq] || 0) + 1}}

      _ ->
        {:noreply, %{state1 | tick_seq: (state1[:tick_seq] || 0) + 1}}
    end
  end

  def handle_call({:add_player, player}, _from, state) do
    new_state = Shard.Combat.Engine.add_player(state, player)
    {:reply, :ok, new_state}
  end

  def handle_call({:remove_player, player_id}, _from, state) do
    new_state = Shard.Combat.Engine.remove_player(state, player_id)
    {:reply, :ok, new_state}
  end

  def handle_call({:update_player, player_id, updates}, _from, state) do
    new_state = Shard.Combat.Engine.update_player(state, player_id, updates)
    {:reply, :ok, new_state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # Add this handle_call callback for adding effects
  def handle_call({:add_effect, effect}, _from, state) do
    effects = Map.get(state, :effects, [])
    new_state = Map.put(state, :effects, [effect | effects])
    {:reply, :ok, new_state}
  end

  def handle_call({:update_monsters, monsters}, _from, state) do
    new_state = Map.put(state, :monsters, monsters)
    {:reply, :ok, new_state}
  end

  defp broadcast_combat_events(state, events) do
    room_pos = state[:room_position]

    if room_pos do
      channel = "room:#{elem(room_pos, 0)},#{elem(room_pos, 1)}"

      Enum.each(events, fn event ->
        Phoenix.PubSub.broadcast(Shard.PubSub, channel, {:combat_event, event})
      end)
    end
  end

  # Public API functions
  def add_player(combat_id, player) do
    GenServer.call(via(combat_id), {:add_player, player})
  end

  def remove_player(combat_id, player_id) do
    GenServer.call(via(combat_id), {:remove_player, player_id})
  end

  def update_player(combat_id, player_id, updates) do
    GenServer.call(via(combat_id), {:update_player, player_id, updates})
  end

  def get_combat_state(combat_id) do
    GenServer.call(via(combat_id), :get_state)
  end

  # Add this public API function for adding effects
  def add_effect(combat_id, effect) do
    GenServer.call(via(combat_id), {:add_effect, effect})
  end
end
