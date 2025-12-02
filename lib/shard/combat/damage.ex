defmodule Shard.Combat.Damage do
  @moduledoc """
  Handles damage calculations and special damage effects.
  """

  def calculate_attack_damage(player_stats, monster, _equipped_weapon) do
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

  def apply_damage_to_monster(monster, damage) do
    new_hp = max((monster[:hp] || 10) - damage, 0)
    is_alive = new_hp > 0

    monster
    |> Map.put(:hp, new_hp)
    |> Map.put(:is_alive, is_alive)
  end

  # NEW: Check for special damage effect
  def check_special_damage_effect(
        game_state,
        original_monster,
        updated_monster,
        base_response,
        combat_id
      ) do
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
