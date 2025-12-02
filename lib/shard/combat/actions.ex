defmodule Shard.Combat.Actions do
  @moduledoc """
  Handles combat actions like attack and flee.
  """

  alias Phoenix.PubSub
  alias Shard.Combat.{Damage, Loot, SharedState}

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
    case SharedState.get_shared_combat_state(combat_id) do
      nil ->
        # Fall back to local monster list for testing or when shared combat isn't available
        local_monsters = game_state.monsters || []
        monsters_here = find_monsters_at_position(local_monsters, {x, y})

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
          Damage.calculate_attack_damage(player_stats_with_id, monster, game_state.equipped_weapon)

        updated_monster = Damage.apply_damage_to_monster(monster, damage_result.final_damage)

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
            Loot.handle_monster_death_local(game_state, updated_monster)

          final_response = response ++ messages

          # Remove dead monster from local list
          final_monsters = Enum.reject(updated_monsters, fn m -> not m[:is_alive] end)

          updated_game_state =
            %{
              game_state
              | player_stats: updated_player_stats,
                character: updated_character,
                monsters: final_monsters
            }

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
          Damage.calculate_attack_damage(player_stats_with_id, monster, game_state.equipped_weapon)

        updated_monster = Damage.apply_damage_to_monster(monster, damage_result.final_damage)

        # Update the shared combat state instead of local monster list
        SharedState.update_shared_monster_state(combat_id, monster, updated_monster)

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
          case Damage.check_special_damage_effect(
                 game_state,
                 monster,
                 updated_monster,
                 response,
                 combat_id
               ) do
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
            Loot.handle_monster_death(game_state, updated_monster, combat_id)

          final_response = final_response ++ messages

          updated_game_state =
            %{game_state | player_stats: updated_player_stats, character: updated_character}

          {final_response, updated_game_state}
        end
    end
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
    SharedState.update_shared_player_state(combat_id, game_state.character.id, %{hp: new_health})

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
end
