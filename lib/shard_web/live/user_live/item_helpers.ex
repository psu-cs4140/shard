defmodule ShardWeb.UserLive.ItemHelpers do
  @moduledoc """
  Helper functions for item management in the MUD game.
  """

  # Use an item from hotbar or inventory
  def use_item(game_state, item) do
    case item.item_type do
      "consumable" ->
        use_consumable_item(game_state, item)

      "weapon" ->
        equip_item(game_state, item)

      "key" ->
        use_key_item(game_state, item)

      _ ->
        response = ["You cannot use #{item.name} in this way."]
        {response, game_state}
    end
  end

  # Use a consumable item (like health potions)
  def use_consumable_item(game_state, item) do
    case item.effect do
      effect when is_binary(effect) ->
        handle_string_effect(game_state, item, effect)

      _ ->
        response = ["You use #{item.name}, but nothing happens."]
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
    
    # Save updated stats to database
    ShardWeb.UserLive.CharacterHelpers.save_character_stats(
      game_state.character,
      updated_stats
    )

    # Remove the item from inventory using database function
    updated_game_state = case Map.get(item, :inventory_id) do
      nil ->
        # Fallback: remove from local state if no inventory_id
        updated_inventory = Enum.reject(game_state.inventory_items, fn inv_item ->
          inv_item.id == item.id
        end)
        %{game_state | player_stats: updated_stats, inventory_items: updated_inventory}

      inventory_id ->
        # Remove from database
        case Shard.Items.remove_item_from_inventory(inventory_id, 1) do
          {:ok, _} ->
            # Reload inventory from database
            updated_inventory = ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)
            %{game_state | player_stats: updated_stats, inventory_items: updated_inventory}

          {:error, _} ->
            # Fallback to local removal if database operation fails
            updated_inventory = Enum.reject(game_state.inventory_items, fn inv_item ->
              inv_item.id == item.id
            end)
            %{game_state | player_stats: updated_stats, inventory_items: updated_inventory}
        end
    end

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
