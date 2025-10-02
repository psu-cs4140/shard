defmodule Shard.Combat do
  @moduledoc """
  Handles all combat-related logic for the game.
  Originally in mud_game_live.ex, then had claude help translate to this module.
  Co-Authored by claude.ai
  """

  alias Shard.Combat.{Damage, Actions}

  @doc """
  Checks if player is currently in combat (has monsters at position).
  """
  def in_combat?(game_state) do
    monsters_at_position(game_state) != []
  end

  @doc """
  Gets all monsters at the player's current position.
  """
  def monsters_at_position(game_state) do
    Enum.filter(game_state.monsters, fn monster ->
      monster[:position] == game_state.player_position
    end)
  end

  @doc """
  Initiates combat when player enters a room with monsters.
  Returns {messages, updated_game_state}.
  """
  def start_combat(game_state) do
    monsters = monsters_at_position(game_state)

    case monsters do
      [] ->
        {[], game_state}

      monsters ->
        messages = build_combat_start_messages(monsters)
        updated_state = %{game_state | combat: true}
        {messages, updated_state}
    end
  end

  @doc """
  Executes a combat action (attack, skill, cast, etc.).
  Returns {messages, updated_game_state}.
  """
  def execute_action(game_state, action) do
    monsters = monsters_at_position(game_state)

    case {action, monsters} do
      {_, []} ->
        {["You are not in combat."], game_state}

      {"attack", [monster | _]} ->
        execute_attack(game_state, monster)

      {"flee", _} ->
        execute_flee(game_state)

      _ ->
        {["Unknown combat action: #{action}"], game_state}
    end
  end

  # Private functions

  defp execute_attack(game_state, target_monster) do
    player_damage = game_state.player_stats.strength

    # Apply damage to monster
    updated_monster = %{target_monster | hp: target_monster.hp - player_damage}

    messages = ["You attack #{target_monster[:name]} for #{player_damage} damage."]

    # Check if monster died
    if updated_monster.hp <= 0 do
      # Monster is dead - remove it and give rewards
      handle_monster_death(game_state, target_monster, messages)
    else
      # Monster survived - update it and let it counterattack
      updated_monsters = replace_monster(game_state.monsters, target_monster, updated_monster)
      messages = messages ++ ["  - #{updated_monster[:name]}: HP = #{updated_monster[:hp]}/#{updated_monster[:hp_max]}"]
      {messages, game_state} = handle_monster_counterattack(game_state, updated_monster, messages)
      game_state = %{game_state | monsters: updated_monsters}

      {messages, game_state}
    end
  end

  defp handle_monster_counterattack(game_state, monster, messages) do
    monster_damage = monster.attack
    new_health = max(0, game_state.player_stats.health - monster_damage)

    updated_stats = %{game_state.player_stats | health: new_health}
    updated_state = %{game_state | player_stats: updated_stats}

    counter_msg = "The #{monster[:name]} attacks you for #{monster_damage} damage."

    {messages ++ [counter_msg], updated_state}
  end

  defp handle_monster_death(game_state, dead_monster, messages) do
    xp_reward = dead_monster[:xp_reward] || 0
    gold_reward = dead_monster[:gold_reward] || 0

    # Remove the monster from the list (use the ORIGINAL monster, not updated one)
    updated_monsters = Enum.reject(game_state.monsters, fn m ->
      m[:position] == dead_monster[:position] and
      m[:monster_id] == dead_monster[:monster_id]
    end)

    updated_stats = game_state.player_stats
    |> Map.update(:experience, 0, &(&1 + xp_reward))

    death_messages = [
      "#{dead_monster[:name]} has been defeated!",
      "You gain #{xp_reward} experience.",
      "On its corpse you find #{gold_reward} gold."
    ]

    updated_state = %{game_state |
      player_stats: updated_stats,
      monsters: updated_monsters
    }

    # Check if combat should end
    check_combat_end(updated_state, messages ++ death_messages)
  end

  defp replace_monster(monsters, old_monster, new_monster) do
    Enum.map(monsters, fn m ->
      if m[:position] == old_monster[:position] and
         m[:name] == old_monster[:name] do
        new_monster
      else
        m
      end
    end)
  end

  defp check_combat_end(game_state, messages) do
    if monsters_at_position(game_state) == [] do
      final_messages = messages ++ ["All monsters have been defeated!"]
      final_state = %{game_state | combat: false}
      {final_messages, final_state}
    else
      {messages, game_state}
    end
  end

  defp build_combat_start_messages(monsters) do
    monster_list = Enum.map_join(monsters, "\n", fn m ->
      "  - #{m[:name]}: HP = #{m[:hp]}/#{m[:hp_max]}"
    end)

    [
      "Combat begins!",
      "Monsters:",
      monster_list,
      "",
      "Actions: attack, flee"
    ]
  end

  defp execute_flee(game_state) do
    # Implement flee logic
    {["You attempt to flee..."], %{game_state | combat: false}}
  end
end
