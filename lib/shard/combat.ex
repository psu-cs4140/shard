defmodule Shard.Combat do
  @moduledoc """
  Combat system for handling player vs monster battles.
  """

  alias Shard.Combat.{Actions, SharedState}

  def in_combat?(game_state) do
    Map.get(game_state, :combat, false) || false
  end

  def execute_action(game_state, action) do
    Actions.execute_action(game_state, action)
  end

  @doc """
  Start combat if there are monsters at the current location.
  """
  def start_combat(game_state) do
    {x, y} = game_state.player_position

    # First check if there are any monsters at the current position
    monsters_at_position =
      Enum.filter(game_state.monsters || [], fn monster ->
        monster[:position] == {x, y} && monster[:is_alive] != false
      end)

    # If no monsters at position, don't start combat
    case monsters_at_position do
      [] ->
        {[], game_state}

      _monsters ->
        # Only initialize shared combat if there are monsters here
        combat_id = "#{x},#{y}"

        case SharedState.ensure_shared_combat_state(combat_id, {x, y}, monsters_at_position) do
          {:ok, combat_state} ->
            # Add player to shared combat (only if combat server is actually running)
            player_data = %{
              id: game_state.character.id,
              name: game_state.character.name,
              position: {x, y},
              hp: game_state.player_stats.health,
              max_hp: game_state.player_stats.max_health
            }

            SharedState.add_player_to_shared_combat(combat_id, player_data)

            # Use the monsters we already found at this position
            messages = build_combat_start_messages(monsters_at_position)
            updated_game_state = Map.put(game_state, :combat, true)
            {messages, updated_game_state}
        end
    end
  end

  defp build_combat_start_messages(monsters) do
    monster_list =
      Enum.map_join(monsters, "\n", fn m ->
        "  - #{m[:name]}: HP = #{m[:hp]}/#{m[:hp_max] || m[:hp]}"
      end)

    [
      "Combat begins!",
      "Monsters:",
      monster_list,
      "",
      "Actions: attack, flee"
    ]
  end
end
