defmodule Shard.Combat do
  @moduledoc """
  Combat system for the MUD game.
  """

  def in_combat?(game_state) do
    Map.get(game_state, :combat, false)
  end

  def execute_action(game_state, action) do
    case action do
      "attack" ->
        {["You attack!"], game_state}
      "flee" ->
        {["You attempt to flee!"], %{game_state | combat: false}}
      _ ->
        {["Unknown combat action."], game_state}
    end
  end

  def start_combat(game_state) do
    # Check if there are monsters at the player's position
    {x, y} = game_state.player_position
    monsters_here = Enum.filter(game_state.monsters, fn monster ->
      monster[:position] == {x, y}
    end)

    if length(monsters_here) > 0 do
      {["Combat begins!"], %{game_state | combat: true}}
    else
      {[], game_state}
    end
  end
end
