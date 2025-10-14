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

  # Use a consumable item (like health potions)
  def use_consumable_item(game_state, item) do
    case item.effect do
      effect when is_binary(effect) ->
        if String.contains?(effect, "Restores") do
          # Parse healing amount from effect string
          healing_amount =
            case Regex.run(~r/(\d+)/, effect) do
              [_, amount] -> String.to_integer(amount)
              # Default healing
              _ -> 25
            end

          current_health = game_state.player_stats.health
          max_health = game_state.player_stats.max_health

          if current_health >= max_health do
            response = ["You are already at full health."]
            {response, game_state}
          else
            new_health = min(current_health + healing_amount, max_health)
            updated_stats = %{game_state.player_stats | health: new_health}
            updated_game_state = %{game_state | player_stats: updated_stats}

            # Save updated stats to database
            ShardWeb.UserLive.CharacterHelpers.save_character_stats(game_state.character, updated_stats)

            response = [
              "You use #{item.name}.",
              "You recover #{new_health - current_health} health points.",
              "Health: #{new_health}/#{max_health}"
            ]

            {response, updated_game_state}
          end
        else
          response = ["You use #{item.name}, but nothing happens."]
          {response, game_state}
        end

      _ ->
        response = ["You use #{item.name}, but nothing happens."]
        {response, game_state}
    end
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
