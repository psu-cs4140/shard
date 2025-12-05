defmodule ShardWeb.UserLive.SpellCommands do
  @moduledoc """
  Handles spell-related commands for the game terminal.
  """

  alias Shard.Spells

  @doc """
  Parse cast command to extract spell name.
  Examples: cast "Holy Incantation", cast 'Fireball', cast Healing Light
  """
  def parse_cast_command(command) do
    cond do
      # Match cast "spell name" or cast 'spell name'
      Regex.match?(~r/^cast\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^cast\s+["'](.+)["']\s*$/i, command) do
          [_, spell_name] -> {:ok, String.trim(spell_name)}
          _ -> :error
        end

      # Match cast spell_name (can be multi-word without quotes)
      Regex.match?(~r/^cast\s+([a-z\s']+)\s*$/i, command) ->
        case Regex.run(~r/^cast\s+([a-z\s']+)\s*$/i, command) do
          [_, spell_name] -> {:ok, String.trim(spell_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  @doc """
  Execute the cast spell command.
  """
  def execute_cast_command(game_state, spell_name) do
    character_id = game_state.character.id
    {x, y} = game_state.player_position

    # Find monsters at current location to use as targets
    monsters_here =
      Enum.filter(game_state.monsters, fn monster ->
        monster[:position] == {x, y} && monster[:is_alive] != false
      end)

    target_id = if length(monsters_here) > 0, do: hd(monsters_here)[:id], else: nil

    case Spells.cast_spell(character_id, spell_name, target_id) do
      {:ok, spell_result} ->
        # Update player_stats mana to match the database
        updated_player_stats = %{
          game_state.player_stats
          | mana: max(0, game_state.player_stats.mana - spell_result.mana_used)
        }

        updated_game_state = %{game_state | player_stats: updated_player_stats}

        handle_spell_result(updated_game_state, spell_result, monsters_here)

      {:error, :spell_not_known} ->
        {[
           "You don't know a spell called '#{spell_name}'. Type 'spells' to see your known spells."
         ], game_state}

      {:error, :insufficient_mana} ->
        {["You don't have enough mana to cast #{spell_name}."], game_state}

      {:error, :level_too_low} ->
        {["You are not high enough level to cast #{spell_name}."], game_state}

      {:error, reason} ->
        {["Failed to cast spell: #{inspect(reason)}"], game_state}
    end
  end

  @doc """
  List all spells known by the character.
  """
  def execute_spells_command(game_state) do
    character_id = game_state.character.id
    known_spells = Spells.list_character_spells(character_id)

    if Enum.empty?(known_spells) do
      response = [
        "You don't know any spells yet.",
        "Find spell scrolls to learn new spells!"
      ]

      {response, game_state}
    else
      response =
        ["Your Known Spells:", ""] ++
          Enum.map(known_spells, fn spell ->
            spell_type = if spell.spell_type, do: " (#{spell.spell_type})", else: ""
            effect_info = build_effect_info(spell)

            "  #{spell.name}#{spell_type} - Mana: #{spell.mana_cost}, Level: #{spell.level_required}#{effect_info}"
          end) ++
          ["", "Use 'cast \"spell name\"' to cast a spell."]

      {response, game_state}
    end
  end

  defp build_effect_info(spell) do
    cond do
      spell.damage && spell.damage > 0 ->
        ", Damage: #{spell.damage}"

      spell.healing && spell.healing > 0 ->
        ", Healing: #{spell.healing}"

      true ->
        ""
    end
  end

  defp handle_spell_result(game_state, spell_result, monsters_here) do
    spell = spell_result.spell
    spell_type = if spell.spell_type, do: spell.spell_type.name, else: "arcane"

    response = ["You cast #{spell.name}!"]

    # Handle different spell effects
    case spell_result.effect_type do
      "Damage" ->
        handle_damage_spell(game_state, spell_result, response, monsters_here, spell_type)

      "Heal" ->
        handle_healing_spell(game_state, spell_result, response)

      "Buff" ->
        handle_buff_spell(game_state, spell_result, response)

      "Debuff" ->
        handle_debuff_spell(game_state, spell_result, response, monsters_here)

      "Stun" ->
        handle_stun_spell(game_state, spell_result, response, monsters_here, spell_type)

      _ ->
        {response ++ ["The spell fizzles with a strange effect!"], game_state}
    end
  end

  defp handle_damage_spell(game_state, spell_result, response, monsters_here, spell_type) do
    if length(monsters_here) > 0 do
      process_damage_spell_with_target(
        game_state,
        spell_result,
        response,
        monsters_here,
        spell_type
      )
    else
      {response ++ ["The spell dissipates harmlessly - there are no enemies here."], game_state}
    end
  end

  defp process_damage_spell_with_target(
         game_state,
         spell_result,
         response,
         monsters_here,
         spell_type
       ) do
    target = hd(monsters_here)
    damage = spell_result.damage || 0

    updated_response =
      response ++
        [
          "#{spell_type_adjective(spell_type)} energy strikes #{target[:name]}!",
          "You deal #{damage} damage!"
        ]

    updated_monsters = update_monster_health(game_state.monsters, target, damage)
    updated_target = Enum.find(updated_monsters, fn m -> m[:id] == target[:id] end)

    final_response = build_damage_response(updated_response, target, updated_target)

    {final_response, %{game_state | monsters: updated_monsters}}
  end

  defp update_monster_health(monsters, target, damage) do
    Enum.map(monsters, fn monster ->
      if monster[:id] == target[:id] do
        new_health = max(0, (monster[:health] || 100) - damage)
        is_dead = new_health == 0

        monster
        |> Map.put(:health, new_health)
        |> Map.put(:is_alive, not is_dead)
      else
        monster
      end
    end)
  end

  defp build_damage_response(updated_response, target, updated_target) do
    if updated_target && (updated_target[:health] == 0 || updated_target[:is_alive] == false) do
      updated_response ++ ["#{target[:name]} has been defeated!"]
    else
      updated_response ++ ["#{target[:name]} has #{updated_target[:health]} health remaining."]
    end
  end

  defp handle_healing_spell(game_state, spell_result, response) do
    healing = spell_result.healing || 0

    updated_response =
      response ++
        [
          "Healing energy washes over you!",
          "You are healed for #{healing} health points."
        ]

    # In a full implementation, would update character health here
    {updated_response, game_state}
  end

  defp handle_buff_spell(game_state, spell_result, response) do
    spell = spell_result.spell

    updated_response =
      response ++
        [
          "You are surrounded by a protective aura!",
          "#{spell.name} empowers you."
        ]

    {updated_response, game_state}
  end

  defp handle_debuff_spell(game_state, _spell_result, response, monsters_here) do
    if length(monsters_here) > 0 do
      target = hd(monsters_here)

      updated_response =
        response ++
          [
            "Dark energy surrounds #{target[:name]}!",
            "#{target[:name]} looks weakened."
          ]

      {updated_response, game_state}
    else
      {response ++ ["The spell dissipates harmlessly - there are no enemies here."], game_state}
    end
  end

  defp handle_stun_spell(game_state, spell_result, response, monsters_here, spell_type) do
    if length(monsters_here) > 0 do
      process_stun_spell_with_target(
        game_state,
        spell_result,
        response,
        monsters_here,
        spell_type
      )
    else
      {response ++ ["The spell dissipates harmlessly - there are no enemies here."], game_state}
    end
  end

  defp process_stun_spell_with_target(
         game_state,
         spell_result,
         response,
         monsters_here,
         spell_type
       ) do
    target = hd(monsters_here)
    damage = spell_result.damage || 0

    updated_response =
      response ++
        [
          "#{spell_type_adjective(spell_type)} energy freezes #{target[:name]} in place!",
          "You deal #{damage} damage and stun your target!"
        ]

    updated_monsters = apply_stun_damage(game_state.monsters, target, damage)

    {updated_response, %{game_state | monsters: updated_monsters}}
  end

  defp apply_stun_damage(monsters, target, damage) do
    Enum.map(monsters, fn monster ->
      if monster[:id] == target[:id] do
        new_health = max(0, (monster[:health] || 100) - damage)
        Map.put(monster, :health, new_health)
      else
        monster
      end
    end)
  end

  defp spell_type_adjective(spell_type) do
    case String.downcase(spell_type || "") do
      "fire" -> "Blazing"
      "ice" -> "Freezing"
      "holy" -> "Divine"
      "shadow" -> "Dark"
      "nature" -> "Natural"
      "arcane" -> "Arcane"
      _ -> "Magical"
    end
  end
end
