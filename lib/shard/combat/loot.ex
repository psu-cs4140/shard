defmodule Shard.Combat.Loot do
  @moduledoc """
  Handles loot drops and monster death rewards.
  """

  alias Shard.Combat.SharedState

  def handle_monster_death_local(game_state, dead_monster) do
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

  def handle_monster_death(game_state, dead_monster, combat_id) do
    # Remove the monster from the shared combat state
    SharedState.remove_shared_monster(combat_id, dead_monster)

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
end
