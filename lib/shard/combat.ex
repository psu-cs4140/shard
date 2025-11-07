defmodule Shard.Combat do
  @moduledoc """
  Combat system for handling player vs monster battles.
  """

  alias Phoenix.PubSub

  def in_combat?(game_state) do
    Map.get(game_state, :combat, false) || false
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
    damage_result =
      calculate_attack_damage(game_state.player_stats, monster, game_state.equipped_weapon)

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

    # NEW: Check for special damage effect
    {final_response, final_monsters} =
      case check_special_damage_effect(game_state, monster, updated_monster, response) do
        {resp, mons} -> {resp, mons}
        nil -> {response, updated_monsters}
      end

    if updated_monster[:is_alive] do
      # Monster survived - handle counterattack
      handle_monster_counterattack(
        game_state,
        updated_monster,
        position,
        final_response,
        final_monsters
      )
    else
      # Monster died - handle death and rewards
      {messages, final_monsters, updated_player_stats, updated_character} =
        handle_monster_death(game_state, updated_monster, final_monsters)

      final_response = final_response ++ messages

      updated_game_state =
        update_combat_state(
          %{game_state | player_stats: updated_player_stats, character: updated_character},
          final_monsters,
          position
        )

      {final_response, updated_game_state}
    end
  end

  defp calculate_attack_damage(player_stats, monster, equipped_weapon) do
    # Parse weapon damage (supports dice notation like "1d4" or plain numbers)
    base_damage = parse_damage(equipped_weapon[:damage] || 10)

    # Add strength modifier
    base_damage = base_damage + (player_stats.strength - 10)

    # Apply random variance (±2)
    variance = 5
    actual_damage = max(base_damage + :rand.uniform(variance) - div(variance, 2), 1)

    # Apply monster armor
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
      updated_monster[:is_alive],
      updated_monster[:hp]
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

    case monsters_here do
      [] ->
        {[], game_state}

      monsters_here ->
        messages = build_combat_start_messages(monsters_here)
        updated_game_state = %{game_state | combat: true}
        {messages, updated_game_state}
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

  defp handle_monster_counterattack(
         game_state,
         monster,
         position,
         attack_messages,
         updated_monsters
       ) do
    # Calculate monster damage
    monster_damage = monster[:attack_damage] || monster[:attack] || 1

    # Apply armor reduction (simple for now - player has no armor yet)
    # In future, could add player armor from equipment
    final_damage = max(monster_damage, 1)

    # Update player health
    new_health = max(game_state.player_stats.health - final_damage, 0)
    updated_stats = %{game_state.player_stats | health: new_health}

    # Broadcast monster attack event for all players (including attacker)
    monster_name = monster[:name] || "monster"

    broadcast_combat_event(
      position,
      {:monster_attack, monster_name, game_state.character.name, final_damage}
    )

    # Update game state and return response (counterattack message comes through broadcast)
    updated_game_state =
      update_combat_state(
        %{game_state | player_stats: updated_stats},
        updated_monsters,
        position
      )

    {attack_messages, updated_game_state}
  end

  defp handle_monster_death(game_state, dead_monster, monsters_list) do
    IO.puts("DEBUG: handle_monster_death called for monster: #{inspect(dead_monster[:name])}")
    IO.puts("DEBUG: Full dead_monster data in handle_monster_death: #{inspect(dead_monster)}")
    
    # Remove the monster from the list
    updated_monsters =
      Enum.reject(monsters_list, fn m ->
        m[:position] == dead_monster[:position] and
          m[:monster_id] == dead_monster[:monster_id]
      end)

    # Award XP and Gold (use defaults if not specified)
    xp_reward = dead_monster[:xp_reward] || dead_monster[:xp_amount] || 10
    gold_reward = dead_monster[:gold_reward] || 5

    # Update player stats - add XP
    updated_stats = Map.update(game_state.player_stats, :experience, 0, &(&1 + xp_reward))

    # Update character - add gold
    updated_character = Map.update(game_state.character, :gold, 0, &(&1 + gold_reward))

    # Process loot drops
    loot_messages = process_loot_drops(game_state, dead_monster)

    # Generate reward messages
    death_messages =
      [
        "You gain #{xp_reward} experience.",
        "You find #{gold_reward} gold on the corpse."
      ] ++ loot_messages

    {death_messages, updated_monsters, updated_stats, updated_character}
  end

  # NEW: Process loot drops when monster dies
  defp process_loot_drops(game_state, dead_monster) do
    IO.puts("DEBUG: Processing loot drops for monster: #{inspect(dead_monster[:name])}")
    IO.puts("DEBUG: Full dead_monster data in process_loot_drops: #{inspect(dead_monster)}")
    IO.puts("DEBUG: Monster's potential_loot_drops: #{inspect(dead_monster[:potential_loot_drops])}")
    
    case dead_monster[:potential_loot_drops] do
      %{} = drops_map ->
        result = process_drops_map(game_state, drops_map)
        IO.puts("DEBUG: Processed drops map, result: #{inspect(result)}")
        result

      nil ->
        IO.puts("DEBUG: No potential_loot_drops found for monster")
        []

      other ->
        IO.puts("DEBUG: Unexpected potential_loot_drops format: #{inspect(other)}")
        []
    end
  end

  defp process_drops_map(game_state, drops_map) do
    drops_map
    |> Enum.reduce([], fn {item_id_str, drop_info}, acc ->
      process_single_drop(game_state, item_id_str, drop_info, acc)
    end)
    |> Enum.reverse()
  end

  defp process_single_drop(game_state, item_id_str, drop_info, acc) do
    IO.puts("DEBUG: Processing single drop - item_id_str: #{inspect(item_id_str)}, drop_info: #{inspect(drop_info)}")
    
    # Convert item_id string back to integer
    case Integer.parse(item_id_str) do
      {item_id, ""} ->
        chance = Map.get(drop_info, :chance, 1.0)
        min_qty = Map.get(drop_info, :min_quantity, 1)
        max_qty = Map.get(drop_info, :max_quantity, 1)
        
        IO.puts("DEBUG: Parsed item_id: #{item_id}, chance: #{chance}, min_qty: #{min_qty}, max_qty: #{max_qty}")

        # Check if item drops
        random_value = :rand.uniform()
        drops = random_value <= chance
        
        IO.puts("DEBUG: Random value: #{random_value}, drops: #{drops}")

        if drops do
          process_successful_drop(game_state, item_id, min_qty, max_qty, acc)
        else
          IO.puts("DEBUG: Item did not drop due to chance")
          acc
        end
        
      :error ->
        IO.puts("DEBUG: Failed to parse item_id_str: #{inspect(item_id_str)}")
        acc
    end
  end

  defp process_successful_drop(game_state, item_id, min_qty, max_qty, acc) do
    # Calculate quantity
    quantity = calculate_drop_quantity(min_qty, max_qty)
    
    IO.puts("DEBUG: Calculated drop quantity: #{quantity}")

    # Add item to player inventory
    case Shard.Items.add_item_to_inventory(
           game_state.character.id,
           item_id,
           quantity
         ) do
      {:ok, _} ->
        IO.puts("DEBUG: Successfully added #{quantity} of item ID #{item_id} to inventory.")
        create_loot_message(item_id, quantity, acc)

      {:error, reason} ->
        IO.puts("DEBUG: Failed to add item ID #{item_id} to inventory. Reason: #{inspect(reason)}")
        # Handle error (log it, maybe drop in room instead)
        acc
    end
  end

  defp calculate_drop_quantity(min_qty, max_qty) do
    if min_qty == max_qty do
      min_qty
    else
      min_qty + :rand.uniform(max_qty - min_qty + 1) - 1
    end
  end

  defp create_loot_message(item_id, quantity, acc) do
    case Shard.Items.get_item(item_id) do
      nil -> 
        IO.puts("DEBUG: Could not find item with ID #{item_id} in database")
        acc
      item -> 
        IO.puts("DEBUG: Found item #{item.name} for loot message")
        ["You find #{quantity} #{item.name} on the corpse." | acc]
    end
  end

  # Helper function to parse damage strings like "1d4" or plain numbers
  defp parse_damage(damage) when is_integer(damage), do: damage

  defp parse_damage(damage) when is_binary(damage) do
    case String.contains?(damage, "d") do
      true ->
        # Parse dice notation like "1d4"
        [num_dice, die_size] = String.split(damage, "d")
        num_dice = String.to_integer(num_dice)
        die_size = String.to_integer(die_size)

        # Roll the dice (simple average for now)
        trunc(num_dice * (die_size + 1) / 2)

      false ->
        # Plain number as string
        String.to_integer(damage)
    end
  end

  # Default fallback
  defp parse_damage(_), do: 1

  # NEW: Check for special damage effect
  defp check_special_damage_effect(game_state, original_monster, updated_monster, base_response) do
    # Check if monster has special damage and is still alive
    if updated_monster[:is_alive] &&
         original_monster[:special_damage_type_id] &&
         original_monster[:special_damage_amount] > 0 &&
         :rand.uniform(100) <= (original_monster[:special_damage_chance] || 100) do
      # Get damage type name
      damage_type = get_damage_type_name(original_monster[:special_damage_type_id])
      amount = original_monster[:special_damage_amount]
      duration = original_monster[:special_damage_duration] || 3

      # Apply special damage effect to combat server
      combat_id = "#{elem(game_state.player_position, 0)},#{elem(game_state.player_position, 1)}"

      # Create effect
      effect = %{
        kind: "special_damage",
        target: {:player, game_state.character.id},
        remaining_ticks: duration,
        magnitude: amount,
        damage_type: damage_type
      }

      # Try to add effect to combat server
      case apply_special_damage_effect(combat_id, effect) do
        :ok ->
          effect_message = "The #{original_monster[:name]}'s attack #{damage_type}s you!"
          effect_response = base_response ++ [effect_message]
          {effect_response, game_state.monsters}

        _ ->
          {base_response, game_state.monsters}
      end
    else
      nil
    end
  end

  # NEW: Get damage type name from database
  defp get_damage_type_name(damage_type_id) do
    case Shard.Repo.get(Shard.Weapons.DamageTypes, damage_type_id) do
      nil -> "unknown"
      damage_type -> String.downcase(damage_type.name)
    end
  end

  # NEW: Apply special damage effect to combat server
  defp apply_special_damage_effect(combat_id, effect) do
    try do
      # Add the effect to the combat server
      Shard.Combat.Server.add_effect(combat_id, effect)
      :ok
    rescue
      _ -> :error
    end
  end
end
