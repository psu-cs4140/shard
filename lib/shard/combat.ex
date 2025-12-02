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
    combat_id = "#{x},#{y}"
    
    # Get shared combat state instead of individual monster list
    case get_shared_combat_state(combat_id) do
      nil ->
        # Fall back to local monster list for testing or when shared combat isn't available
        monsters_here = find_monsters_at_position(game_state.monsters || [], {x, y})
        
        case monsters_here do
          [] ->
            {["There are no monsters here to attack."], game_state}

          [monster | _] ->
            perform_local_attack(game_state, monster, {x, y})
        end
        
      combat_state ->
        monsters_here = find_monsters_at_position(combat_state.monsters || [], {x, y})
        
        case monsters_here do
          [] ->
            {["There are no monsters here to attack."], game_state}

          [monster | _] ->
            perform_shared_attack(game_state, monster, {x, y}, combat_id)
        end
    end
  end

  defp find_monsters_at_position(monsters, position) do
    Enum.filter(monsters, fn monster ->
      monster[:position] == position && monster[:is_alive] != false
    end)
  end

  defp perform_local_attack(game_state, monster, _position) do
    # Check if this is The Count and player has required item
    case check_count_attack_requirements(game_state, monster) do
      {:error, message} ->
        {[message], game_state}

      :ok ->
        # Add character_id to player_stats for weapon lookup
        player_stats_with_id =
          Map.put(game_state.player_stats, :character_id, game_state.character.id)

        damage_result =
          calculate_attack_damage(player_stats_with_id, monster, game_state.equipped_weapon)

        updated_monster = apply_damage_to_monster(monster, damage_result.final_damage)
        
        # Update local monster list for testing
        updated_monsters = update_monsters_list(game_state.monsters, monster, updated_monster)

        response = create_attack_response(monster, damage_result, updated_monster)

        if updated_monster[:is_alive] do
          # Monster survived - simple response for local testing
          updated_game_state = %{game_state | monsters: updated_monsters}
          {response, updated_game_state}
        else
          # Monster died - handle death and rewards
          {messages, updated_player_stats, updated_character} =
            handle_monster_death_local(game_state, updated_monster)

          final_response = response ++ messages
          
          # Remove dead monster from local list
          final_monsters = Enum.reject(updated_monsters, fn m -> not m[:is_alive] end)

          updated_game_state =
            %{game_state | 
              player_stats: updated_player_stats, 
              character: updated_character,
              monsters: final_monsters}

          {final_response, updated_game_state}
        end
    end
  end

  defp perform_shared_attack(game_state, monster, position, combat_id) do
    # Check if this is The Count and player has required item
    case check_count_attack_requirements(game_state, monster) do
      {:error, message} ->
        {[message], game_state}

      :ok ->
        # Add character_id to player_stats for weapon lookup
        player_stats_with_id =
          Map.put(game_state.player_stats, :character_id, game_state.character.id)

        damage_result =
          calculate_attack_damage(player_stats_with_id, monster, game_state.equipped_weapon)

        updated_monster = apply_damage_to_monster(monster, damage_result.final_damage)
        
        # Update the shared combat state instead of local monster list
        update_shared_monster_state(combat_id, monster, updated_monster)

        response = create_attack_response(monster, damage_result, updated_monster)

        broadcast_attack_event(
          position,
          game_state.character.name,
          monster,
          damage_result,
          updated_monster
        )

        # NEW: Check for special damage effect
        final_response =
          case check_special_damage_effect(game_state, monster, updated_monster, response, combat_id) do
            {resp, _} -> resp
            nil -> response
          end

        if updated_monster[:is_alive] do
          # Monster survived - handle counterattack
          handle_monster_counterattack(
            game_state,
            updated_monster,
            position,
            final_response,
            combat_id
          )
        else
          # Monster died - handle death and rewards
          {messages, updated_player_stats, updated_character} =
            handle_monster_death(game_state, updated_monster, combat_id)

          final_response = final_response ++ messages

          updated_game_state =
            %{game_state | player_stats: updated_player_stats, character: updated_character}

          {final_response, updated_game_state}
        end
    end
  end

  defp calculate_attack_damage(player_stats, monster, _equipped_weapon) do
    # Get the current equipped weapon from database to ensure we have latest data
    current_weapon = get_current_equipped_weapon(player_stats.character_id)

    # Get attack power from weapon (0 if no weapon equipped)
    weapon_attack_power =
      case current_weapon do
        %{attack_power: attack_power} when is_integer(attack_power) ->
          attack_power

        %{attack_power: attack_power} when is_binary(attack_power) ->
          String.to_integer(attack_power)

        %{damage: damage} when not is_nil(damage) ->
          damage

        _ ->
          0
      end

    # Calculate base damage as strength + weapon attack power
    base_damage = player_stats.strength + weapon_attack_power

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
    combat_id = "#{x},#{y}"

    # Initialize or join shared combat state
    case ensure_shared_combat_state(combat_id, {x, y}, game_state.monsters) do
      {:ok, combat_state} ->
        # Add player to shared combat (only if combat server is actually running)
        player_data = %{
          id: game_state.character.id,
          name: game_state.character.name,
          position: {x, y},
          hp: game_state.player_stats.health,
          max_hp: game_state.player_stats.max_health
        }
        
        add_player_to_shared_combat(combat_id, player_data)

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

  defp handle_monster_counterattack(
         game_state,
         monster,
         position,
         attack_messages,
         combat_id
       ) do
    # Calculate monster damage
    monster_damage = monster[:attack_damage] || monster[:attack] || 1

    # Apply armor reduction (simple for now - player has no armor yet)
    # In future, could add player armor from equipment
    final_damage = max(monster_damage, 1)

    # Update player health
    current_health = Map.get(game_state.player_stats, :health, 100)
    new_health = max(current_health - final_damage, 0)
    updated_stats = Map.put(game_state.player_stats, :health, new_health)

    # Update player in shared combat state
    update_shared_player_state(combat_id, game_state.character.id, %{hp: new_health})

    # Broadcast monster attack event for all players (including attacker)
    monster_name = monster[:name] || "monster"

    broadcast_combat_event(
      position,
      {:monster_attack, monster_name, game_state.character.name, final_damage}
    )

    # Update game state and return response (counterattack message comes through broadcast)
    updated_game_state = %{game_state | player_stats: updated_stats}

    {attack_messages, updated_game_state}
  end

  defp handle_monster_death_local(game_state, dead_monster) do
    # Award XP and Gold (use defaults if not specified)
    xp_reward = dead_monster[:xp_reward] || dead_monster[:xp_amount] || 10
    gold_reward = dead_monster[:gold_reward] || 5

    # Update player stats - add XP
    updated_stats = Map.update(game_state.player_stats, :experience, 0, &(&1 + xp_reward))

    # Update character - add gold
    updated_character = Map.update(game_state.character, :gold, 0, &(&1 + gold_reward))

    # Generate reward messages (skip loot processing for local testing)
    death_messages = [
      "You gain #{xp_reward} experience.",
      "You find #{gold_reward} gold on the corpse."
    ]

    {death_messages, updated_stats, updated_character}
  end

  defp handle_monster_death(game_state, dead_monster, combat_id) do
    # Remove the monster from the shared combat state
    remove_shared_monster(combat_id, dead_monster)

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

    {death_messages, updated_stats, updated_character}
  end

  # NEW: Process loot drops when monster dies
  defp process_loot_drops(game_state, dead_monster) do
    case dead_monster[:potential_loot_drops] do
      %{} = drops_map ->
        process_drops_map(game_state, drops_map)

      nil ->
        []

      _other ->
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
    # Convert item_id string back to integer
    case Integer.parse(item_id_str) do
      {item_id, ""} ->
        # Use string keys since data comes from database
        chance = Map.get(drop_info, "chance", 1.0)
        min_qty = Map.get(drop_info, "min_quantity", 1)
        max_qty = Map.get(drop_info, "max_quantity", 1)

        # Check if item drops
        random_value = :rand.uniform()
        drops = random_value <= chance

        if drops do
          process_successful_drop(game_state, item_id, min_qty, max_qty, acc)
        else
          acc
        end

      :error ->
        acc
    end
  end

  defp process_successful_drop(game_state, item_id, min_qty, max_qty, acc) do
    # Calculate quantity
    quantity = calculate_drop_quantity(min_qty, max_qty)

    # Verify the item exists first
    case Shard.Items.get_item(item_id) do
      nil ->
        acc

      _item ->
        # Add item to player inventory using the exact same pattern as pickup
        case add_item_to_character_inventory(game_state.character.id, item_id, quantity) do
          {:ok, _} ->
            create_loot_message(item_id, quantity, acc)

          {:error, _reason} ->
            acc
        end
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
        acc

      item ->
        ["You find #{quantity} #{item.name} on the corpse." | acc]
    end
  end

  # Helper function to get currently equipped weapon from database
  defp get_current_equipped_weapon(character_id) do
    try do
      equipped_items = Shard.Items.get_equipped_items(character_id)

      # Look for weapon in main_hand slot (not "weapon" slot)
      case Map.get(equipped_items, "main_hand") do
        nil ->
          # No weapon equipped, return nil for unarmed combat
          nil

        weapon ->
          # Check for attack_power first, then fallback to damage for legacy weapons
          # Handle both parsed maps and JSON strings
          parsed_stats =
            case weapon.stats do
              %{} = stats_map ->
                stats_map

              stats_string when is_binary(stats_string) ->
                case Jason.decode(stats_string) do
                  {:ok, parsed} ->
                    parsed

                  {:error, _} ->
                    %{}
                end

              _ ->
                %{}
            end

          attack_value =
            case parsed_stats do
              %{"attack_power" => attack_power} when is_integer(attack_power) ->
                attack_power

              %{"attack_power" => attack_power} when is_binary(attack_power) ->
                String.to_integer(attack_power)

              _ ->
                weapon.damage || 0
            end

          %{
            attack_power: attack_value,
            # Keep for legacy compatibility
            damage: weapon.damage,
            name: weapon.name,
            id: weapon.id
          }
      end
    rescue
      # Handle case where database table doesn't exist (e.g., in tests)
      Postgrex.Error ->
        nil

      _error ->
        nil
    end
  end

  # Helper function to add items to character inventory
  defp add_item_to_character_inventory(character_id, item_id, quantity) do
    # Use the exact same pattern as the pickup logic in Items context
    result = Shard.Items.add_item_to_inventory(character_id, item_id, quantity)

    case result do
      {:ok, _} = success ->
        success

      {:error, _reason} = error ->
        error

      _other ->
        {:error, :unexpected_result}
    end
  end

  # NEW: Check for special damage effect
  defp check_special_damage_effect(game_state, original_monster, updated_monster, base_response, combat_id) do
    # Check if monster has special damage and is still alive
    if updated_monster[:is_alive] &&
         original_monster[:special_damage_type_id] &&
         original_monster[:special_damage_amount] > 0 &&
         :rand.uniform(100) <= (original_monster[:special_damage_chance] || 100) do
      # Get damage type name
      damage_type = get_damage_type_name(original_monster[:special_damage_type_id])
      amount = original_monster[:special_damage_amount]
      duration = original_monster[:special_damage_duration] || 3

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
          {effect_response, nil}

        _ ->
          {base_response, nil}
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

  # Check if player can attack The Count (requires Mythical Tome)
  defp check_count_attack_requirements(game_state, monster) do
    case monster[:name] do
      "The Count" ->
        if Shard.Items.character_has_item?(game_state.character.id, "Mythical Tome") do
          :ok
        else
          {:error,
           "The Count's dark power repels your attack! You need something more powerful to face him..."}
        end

      _ ->
        :ok
    end
  end

  # Helper functions for shared combat state management
  defp get_shared_combat_state(combat_id) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] -> 
          # Process doesn't exist
          nil
        [{_pid, _}] ->
          # Process exists, try to get state
          Shard.Combat.Server.get_combat_state(combat_id)
      end
    rescue
      _ -> nil
    catch
      :exit, _ -> nil
    end
  end

  defp ensure_shared_combat_state(combat_id, position, monsters) do
    case get_shared_combat_state(combat_id) do
      nil ->
        # Start new combat server
        initial_state = %{
          combat_id: combat_id,
          room_position: position,
          monsters: monsters || [],
          players: [],
          effects: [],
          combat: true
        }
        
        # Check if supervisor is available before trying to start child
        case Process.whereis(Shard.Combat.Supervisor) do
          nil ->
            # Supervisor not available, fall back to local state with monsters
            {:ok, initial_state}
          
          _pid ->
            # Use the correct child spec format for DynamicSupervisor
            child_spec = %{
              id: {Shard.Combat.Server, combat_id},  # Make ID unique per combat
              start: {Shard.Combat.Server, :start_link, [initial_state]},
              restart: :temporary
            }
            
            case DynamicSupervisor.start_child(Shard.Combat.Supervisor, child_spec) do
              {:ok, _pid} -> 
                # Wait a moment for the process to initialize
                :timer.sleep(10)
                {:ok, initial_state}
              {:error, {:already_started, _pid}} -> 
                {:ok, get_shared_combat_state(combat_id) || initial_state}
              _error -> 
                # Fall back to local state if server start fails
                {:ok, initial_state}
            end
        end

      state ->
        {:ok, state}
    end
  end

  defp add_player_to_shared_combat(combat_id, player_data) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] -> 
          :error
        [{_pid, _}] ->
          Shard.Combat.Server.add_player(combat_id, player_data)
      end
    rescue
      _ -> :error
    catch
      :exit, _ -> :error
    end
  end

  defp update_shared_monster_state(combat_id, original_monster, updated_monster) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] -> 
          :error
        [{_pid, _}] ->
          # Get current combat state
          case get_shared_combat_state(combat_id) do
            nil -> :error
            combat_state ->
              # Update the monster in the monsters list
              updated_monsters = update_monsters_list(combat_state.monsters || [], original_monster, updated_monster)
              
              # Update the combat state
              GenServer.call(Shard.Combat.Server.via(combat_id), {:update_monsters, updated_monsters})
          end
      end
    rescue
      _ -> :error
    catch
      :exit, _ -> :error
    end
  end

  defp update_shared_player_state(combat_id, player_id, updates) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] -> 
          :error
        [{_pid, _}] ->
          Shard.Combat.Server.update_player(combat_id, player_id, updates)
      end
    rescue
      _ -> :error
    catch
      :exit, _ -> :error
    end
  end

  defp remove_shared_monster(combat_id, dead_monster) do
    try do
      # Check if the process exists first
      case Registry.lookup(Shard.Registry, {:combat, combat_id}) do
        [] -> 
          :error
        [{_pid, _}] ->
          case get_shared_combat_state(combat_id) do
            nil -> :error
            combat_state ->
              updated_monsters = 
                Enum.reject(combat_state.monsters || [], fn m ->
                  m[:position] == dead_monster[:position] and
                    m[:monster_id] == dead_monster[:monster_id]
                end)
              
              GenServer.call(Shard.Combat.Server.via(combat_id), {:update_monsters, updated_monsters})
          end
      end
    rescue
      _ -> :error
    catch
      :exit, _ -> :error
    end
  end
end
