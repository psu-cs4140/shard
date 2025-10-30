defmodule Shard.Combat do
  @moduledoc """
  Combat system for handling player vs monster battles.
  """

  alias Phoenix.PubSub

  def in_combat?(game_state) do
    game_state.combat || false
  end

  def execute_action(game_state, action) do
    case action do
      "attack" ->
        execute_attack(game_state)

      "flee" ->
        execute_flee(game_state)

      _ ->
        {["Unknown combat action."], game_state}
    end
  end

  defp execute_attack(game_state) do
    {x, y} = game_state.player_position
    monsters_here = find_monsters_at_position(game_state.monsters, {x, y})

    case monsters_here do
      [] ->
        {["There are no monsters here to attack."], game_state}

      [monster | _] ->
        perform_attack(game_state, monster, {x, y})
    end
  end

  defp find_monsters_at_position(monsters, position) do
    Enum.filter(monsters, fn monster ->
      monster[:position] == position && monster[:is_alive] != false
    end)
  end

  defp perform_attack(game_state, monster, position) do
    damage_result = calculate_attack_damage(game_state.player_stats, monster)
    updated_monster = apply_damage_to_monster(monster, damage_result.final_damage)
    updated_monsters = update_monsters_list(game_state.monsters, monster, updated_monster)

    response = create_attack_response(monster, damage_result, updated_monster)

    broadcast_attack_event(
      position,
      game_state.character.name,
      monster,
      damage_result,
      updated_monster
    )

    updated_game_state = update_combat_state(game_state, updated_monsters, position)
    {response, updated_game_state}
  end

  defp calculate_attack_damage(player_stats, monster) do
    base_damage = 10 + (player_stats.strength - 10)
    variance = 5
    actual_damage = max(base_damage + :rand.uniform(variance) - div(variance, 2), 1)
    armor = monster[:armor] || 0
    final_damage = max(actual_damage - armor, 1)

    %{actual_damage: actual_damage, final_damage: final_damage}
  end

  defp apply_damage_to_monster(monster, damage) do
    new_hp = max((monster[:hp] || 10) - damage, 0)
    is_alive = new_hp > 0

    monster
    |> Map.put(:hp, new_hp)
    |> Map.put(:is_alive, is_alive)
  end

  defp update_monsters_list(monsters, original_monster, updated_monster) do
    Enum.map(monsters, fn m ->
      if m == original_monster, do: updated_monster, else: m
    end)
  end

  defp create_attack_response(monster, damage_result, updated_monster) do
    monster_name = monster[:name] || "monster"
    attack_msg = "You attack the #{monster_name} for #{damage_result.final_damage} damage!"

    if updated_monster[:is_alive] do
      [attack_msg, "The #{monster_name} has #{updated_monster[:hp]} health remaining."]
    else
      [attack_msg, "The #{monster_name} is defeated!"]
    end
  end

  defp broadcast_attack_event(position, player_name, monster, damage_result, updated_monster) do
    monster_name = monster[:name] || "monster"

    broadcast_combat_event(position, {
      :player_attack,
      player_name,
      monster_name,
      damage_result.final_damage,
      updated_monster[:is_alive]
    })
  end

  defp update_combat_state(game_state, updated_monsters, position) do
    combat_active =
      Enum.any?(updated_monsters, fn m ->
        m[:position] == position && m[:is_alive] != false
      end)

    %{game_state | monsters: updated_monsters, combat: combat_active}
  end

  defp execute_flee(game_state) do
    # Simple flee mechanic - always succeeds for now
    updated_game_state = %{game_state | combat: false}

    # Broadcast flee event
    {x, y} = game_state.player_position
    broadcast_combat_event({x, y}, {:player_fled, game_state.character.name})

    {["You flee from combat!"], updated_game_state}
  end

  defp broadcast_combat_event({x, y}, event) do
    channel = "room:#{x},#{y}"
    PubSub.broadcast(Shard.PubSub, channel, {:combat_action, event})
  end

  @doc """
  Start combat if there are monsters at the current location.
  """
  def start_combat(game_state) do
    {x, y} = game_state.player_position

    # Check if there are monsters at current location
    monsters_here =
      Enum.filter(game_state.monsters, fn monster ->
        monster[:position] == {x, y} && monster[:is_alive] != false
      end)

    if length(monsters_here) > 0 do
      # Start combat
      updated_game_state = %{game_state | combat: true}
      {[], updated_game_state}
    else
      # No monsters, no combat
      {[], game_state}
    end
  end
end
