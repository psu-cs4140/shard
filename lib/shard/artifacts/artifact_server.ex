defmodule Shard.Artifacts.ArtifactServer do
  @moduledoc """
  This module defines a GenServer that simulates the game-world
  feature of a healing fountain, which periodically applies 
  a healing effect to a certain area
  """

  use GenServer

  def start_link(_) do
    state = %{
      name: "Healing Fountain",
      effect: {:area_heal, 5, "The healing fountain emits a fine mist of soothing water."},
      tick_delay: 3_000,
      position: {2, 1}
    }

    GenServer.start_link(__MODULE__, state)
  end

  @impl true
  def init(state) do
    Process.send_after(self(), :tick, state.tick_delay)
    {:ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    Process.send_after(self(), :tick, state.tick_delay)
    chan = posn_to_room_channel(state.position)
    Phoenix.PubSub.broadcast(Shard.PubSub, chan, state.effect)
    {:noreply, state}
  end

  def posn_to_room_channel({xx, yy}) do
    "room:#{xx},#{yy}"
  end
end
