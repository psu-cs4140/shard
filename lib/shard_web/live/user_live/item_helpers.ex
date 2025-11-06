defmodule ShardWeb.UserLive.ItemHelpers do
  @moduledoc """
  Helper functions for item management in the MUD game.
  """

  # Use an item from hotbar or inventory
  def use_item(game_state, item) do
    case item.type do
      "consumable" ->
        use_consumable_item(game_state, item)

      "weapon" ->
        equip_item(game_state, item)

      _ ->
        response = ["You cannot use #{item.name} in this way."]
        {response, game_state}
    end
  end

  # Use a consumable item (like health potions or spell scrolls)
  def use_consumable_item(game_state, item) do
    # Check if it's a spell scroll
    if is_spell_scroll?(item) do
      use_spell_scroll_item(game_state, item)
    else
      case item.effect do
        effect when is_binary(effect) ->
          handle_string_effect(game_state, item, effect)

        _ ->
          response = ["You use #{item.name}, but nothing happens."]
          {response, game_state}
      end
    end
  end

  defp is_spell_scroll?(item) do
    Map.has_key?(item, :spell_id) and not is_nil(item.spell_id)
  end

  defp use_spell_scroll_item(game_state, item) do
    character_id = game_state.character.id
    inventory_id = item[:inventory_id] || item[:id]

    case Shard.Items.use_spell_scroll(character_id, inventory_id) do
      {:ok, :learned, spell} ->
        response = [
          "You read the #{item.name}!",
          "You have learned the spell: #{spell.name}",
          "The scroll crumbles to dust as its magic is absorbed.",
          "Use 'spells' to see your known spells."
        ]
        {response, game_state}

      {:ok, :already_known, spell} ->
        response = [
          "You read the #{item.name}.",
          "You already know the spell: #{spell.name}",
          "The scroll crumbles to dust, its magic already within you."
        ]
        {response, game_state}

      {:error, :not_a_spell_scroll} ->
        response = ["This is not a spell scroll."]
        {response, game_state}

      {:error, _reason} ->
        response = ["Failed to use #{item.name}."]
        {response, game_state}
    end
  end

  defp handle_string_effect(game_state, item, effect) do
    if String.contains?(effect, "Restores") do
      apply_healing_effect(game_state, item, effect)
    else
      response = ["You use #{item.name}, but nothing happens."]
      {response, game_state}
    end
  end

  defp apply_healing_effect(game_state, item, effect) do
    healing_amount = parse_healing_amount(effect)
    current_health = game_state.player_stats.health
    max_health = game_state.player_stats.max_health

    if current_health >= max_health do
      response = ["You are already at full health."]
      {response, game_state}
    else
      perform_healing(game_state, item, healing_amount, current_health, max_health)
    end
  end

  defp parse_healing_amount(effect) do
    case Regex.run(~r/(\d+)/, effect) do
      [_, amount] -> String.to_integer(amount)
      # Default healing
      _ -> 25
    end
  end

  defp perform_healing(game_state, item, healing_amount, current_health, max_health) do
    new_health = min(current_health + healing_amount, max_health)
    updated_stats = %{game_state.player_stats | health: new_health}
    updated_game_state = %{game_state | player_stats: updated_stats}

    # Save updated stats to database
    ShardWeb.UserLive.CharacterHelpers.save_character_stats(
      game_state.character,
      updated_stats
    )

    response = [
      "You use #{item.name}.",
      "You recover #{new_health - current_health} health points.",
      "Health: #{new_health}/#{max_health}"
    ]

    {response, updated_game_state}
  end

  # Equip an item (weapons, armor, etc.)
  def equip_item(game_state, item) do
    case item.type do
      "weapon" ->
        old_weapon = game_state.equipped_weapon
        updated_game_state = %{game_state | equipped_weapon: item}

        response = [
          "You equip #{item.name}.",
          "You unequip #{old_weapon.name}."
        ]

        {response, updated_game_state}

      "armor" ->
        # For now, just show a message since we don't have equipped armor tracking yet
        response = [
          "You equip #{item.name}.",
          "Your defense increases!"
        ]

        {response, game_state}

      _ ->
        response = ["You cannot equip #{item.name}."]
        {response, game_state}
    end
  end
end
