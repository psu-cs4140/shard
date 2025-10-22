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
           function_exported?(Shard.Combat.Engine, :tick, 1) do
        apply(Shard.Combat.Engine, :tick, [state1])
      else
        {:ok, state1, state1[:events] || []}
      end

    case result do
      {:ok, s2, _events} ->
        {:noreply, %{s2 | tick_seq: (s2[:tick_seq] || 0) + 1}}

      _ ->
        {:noreply, %{state1 | tick_seq: (state1[:tick_seq] || 0) + 1}}
    end
  end
end
