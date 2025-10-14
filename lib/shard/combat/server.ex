defmodule Shard.Combat.Server do
  @moduledoc false
  use GenServer
  alias Shard.Combat.Engine

  @tick_ms 1000

  def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, opts)

  @impl true
  def init(opts) do
    state =
      Map.new(opts)
      |> Map.put_new(:tick_seq, 0)
      |> Map.put_new(:monsters, [])
      |> Map.put_new(:effects, [])
      |> Map.put_new(:combat, false)

    :timer.send_interval(@tick_ms, :tick)
    {:ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    {:ok, s2, _events} = Engine.step(state)
    {:noreply, %{s2 | tick_seq: s2.tick_seq + 1}}
  end
end
