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
    combat_id = "#{x},#{y}"

    # Initialize or join shared combat state
    case SharedState.ensure_shared_combat_state(combat_id, {x, y}, game_state.monsters) do
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

        # Check if there are monsters at current location
        # In test environment, combat_state.monsters might be empty even when game_state has monsters
        # So we need to check both sources, but always filter by position first
        combat_monsters = combat_state.monsters || []
        game_monsters = game_state.monsters || []

        # Filter combat monsters by position first
        combat_monsters_here =
          Enum.filter(combat_monsters, fn monster ->
            monster[:position] == {x, y} && monster[:is_alive] != false
          end)

        # If no combat monsters at position, check game monsters at position
        monsters_here =
          if length(combat_monsters_here) > 0 do
            combat_monsters_here
          else
            Enum.filter(game_monsters, fn monster ->
              monster[:position] == {x, y} && monster[:is_alive] != false
            end)
          end

        case monsters_here do
          [] ->
            {[], game_state}

          monsters_here ->
            messages = build_combat_start_messages(monsters_here)
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
