defmodule ShardWeb.UserLive.ItemHelpers do
  @moduledoc """
  Helper functions for item management in the MUD game.
  """

  @equip_message_templates %{
    "weapon" => "You equip {item_name} as your weapon.",
    "shield" => "You equip your mighty {item_name} for protection.",
    "head" => "You equip {item_name} on your head.",
    "body" => "You equip {item_name} on your body.",
    "legs" => "You equip {item_name} on your legs.",
    "feet" => "You equip {item_name} on your feet.",
    "ring" => "You slide {item_name} on one of your fingers.",
    "necklace" => "You place {item_name} around your neck."
  }

  # Use an item from hotbar or inventory
  def use_item(game_state, item) do
    cond do
      Shard.Kitchen.food_effect(item.name) ->
        consume_food(game_state, item)

      true ->
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
  end

  # Use a consumable item (like health potions or spell scrolls)
  def use_consumable_item(game_state, item) do
    # Check if it's a spell scroll
    if spell_scroll?(item) do
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

  defp spell_scroll?(item) do
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

  defp consume_food(game_state, item) do
    effects = Shard.Kitchen.food_effect(item.name)

    cond do
      is_nil(effects) ->
        {["You cannot use #{item.name} in this way."], game_state}

      not Shard.Combat.in_combat?(game_state) ->
        {["You can only eat #{item.name} during combat."], game_state}

      true ->
        case find_food_inventory_entry(game_state, item) do
          {:ok, entry} ->
            apply_food_effect(game_state, item, effects, entry)

          :not_found ->
            {["You have no more #{item.name} to eat."], game_state}
        end
    end
  end

  defp find_food_inventory_entry(game_state, item) do
    cond do
      Map.get(item, :inventory_id) ->
        inventory_id = Map.get(item, :inventory_id)

        case Enum.find(game_state.inventory_items, &(&1.inventory_id == inventory_id)) do
          nil -> :not_found
          entry -> {:ok, entry}
        end

      true ->
        case Enum.find(game_state.inventory_items, fn inv_item ->
               inv_item.name == item.name && inv_item.quantity > 0
             end) do
          nil -> :not_found
          entry -> {:ok, entry}
        end
    end
  end

  defp apply_food_effect(game_state, item, %{hp: hp, mana: mana}, entry) do
    current_health = game_state.player_stats.health
    max_health = game_state.player_stats.max_health
    current_mana = game_state.player_stats.mana
    max_mana = game_state.player_stats.max_mana

    healed = min(hp, max(max_health - current_health, 0))
    restored_mana = min(mana, max(max_mana - current_mana, 0))

    if healed <= 0 and restored_mana <= 0 do
      {["You are already at full strength and mana."], game_state}
    else
      updated_stats = %{
        game_state.player_stats
        | health: current_health + healed,
          mana: current_mana + restored_mana
      }

      ShardWeb.UserLive.CharacterHelpers.save_character_stats(game_state.character, updated_stats)

      case Shard.Items.remove_item_from_inventory(entry.inventory_id, 1) do
        {:ok, _} ->
          updated_inventory =
            ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)

          base_character =
            game_state.character
            |> Map.put(:health, updated_stats.health)
            |> Map.put(:mana, updated_stats.mana)

          {updated_character, updated_hotbar} = reload_character_hotbar(base_character)

          response =
            case {healed > 0, restored_mana > 0} do
              {true, true} ->
                [
                  "You eat #{item.name} and recover #{healed} HP and #{restored_mana} Mana.",
                  "HP: #{updated_stats.health}/#{max_health} | Mana: #{updated_stats.mana}/#{max_mana}"
                ]

              {true, false} ->
                [
                  "You eat #{item.name} and recover #{healed} HP.",
                  "HP: #{updated_stats.health}/#{max_health}"
                ]

              {false, true} ->
                [
                  "You eat #{item.name} and recover #{restored_mana} Mana.",
                  "Mana: #{updated_stats.mana}/#{max_mana}"
                ]
            end

          updated_game_state =
            game_state
            |> Map.put(:player_stats, updated_stats)
            |> Map.put(:inventory_items, updated_inventory)
            |> Map.put(:character, updated_character)
            |> Map.put(:hotbar, updated_hotbar)

          {response, updated_game_state}

        {:error, reason} ->
          {["Failed to consume #{item.name}: #{inspect(reason)}"], game_state}
      end
    end
  end

  defp reload_character_hotbar(character) do
    slots = Shard.Items.get_character_hotbar(character.id)
    updated_character = %{character | hotbar_slots: slots}
    hotbar = ShardWeb.UserLive.CharacterHelpers.load_character_hotbar(updated_character)
    {updated_character, hotbar}
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
    updated_game_state =
      case Map.get(item, :inventory_id) do
        nil ->
          # Fallback: remove from local state if no inventory_id
          updated_inventory =
            Enum.reject(game_state.inventory_items, fn inv_item ->
              inv_item.id == item.id
            end)

          %{game_state | player_stats: updated_stats, inventory_items: updated_inventory}

        inventory_id ->
          # Remove from database
          case Shard.Items.remove_item_from_inventory(inventory_id, 1) do
            {:ok, _} ->
              # Reload inventory from database
              updated_inventory =
                ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)

              %{game_state | player_stats: updated_stats, inventory_items: updated_inventory}

            {:error, _} ->
              # Fallback to local removal if database operation fails
              updated_inventory =
                Enum.reject(game_state.inventory_items, fn inv_item ->
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
    case Map.get(item, :inventory_id) do
      nil -> handle_missing_inventory_reference(item, game_state)
      inventory_id -> handle_item_equipping(game_state, item, inventory_id)
    end
  end

  defp handle_missing_inventory_reference(item, game_state) do
    response = ["Cannot equip #{item.name} - no inventory reference found."]
    {response, game_state}
  end

  defp handle_item_equipping(game_state, item, inventory_id) do
    case Shard.Items.equip_item(inventory_id) do
      {:ok, _} -> handle_successful_equip(game_state, item)
      {:error, reason} -> handle_equip_error(item, reason, game_state)
    end
  end

  defp handle_successful_equip(game_state, item) do
    updated_inventory =
      ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)

    updated_game_state = %{game_state | inventory_items: updated_inventory}
    equipment_slot = Map.get(item, :equipment_slot) || item.item_type
    message = generate_equip_message(item.name, equipment_slot)

    {[message], updated_game_state}
  end

  defp handle_equip_error(item, reason, game_state) do
    message =
      case reason do
        :not_equippable -> "#{item.name} cannot be equipped."
        :already_equipped -> "#{item.name} is already equipped."
        _ -> "Failed to equip #{item.name}: #{reason}"
      end

    {[message], game_state}
  end

  defp generate_equip_message(item_name, equipment_slot) do
    message_template = get_equip_message_template(equipment_slot)
    String.replace(message_template, "{item_name}", item_name)
  end

  defp get_equip_message_template(equipment_slot) do
    Map.get(@equip_message_templates, equipment_slot, "You equip {item_name}.")
  end

  # Use a key to unlock doors
  def use_key_item(game_state, key) do
    # Get current room from character position and zone
    character = game_state.character
    {x, y} = game_state.player_position

    case find_locked_doors_for_key(character.current_zone_id, x, y, key) do
      [] ->
        response = ["There are no locked doors here that #{key.name} can unlock."]
        {response, game_state}

      doors ->
        unlock_doors_with_key(game_state, doors, key)
    end
  end

  defp find_locked_doors_for_key(zone_id, x, y, key) do
    # Get current room
    case Shard.Map.get_room_by_coordinates(zone_id, x, y) do
      nil ->
        []

      room ->
        # Get all doors from this room that are locked and match the key
        doors = Shard.Map.get_doors_from_room(room.id)

        Enum.filter(doors, fn door ->
          door_is_locked?(door) && key_matches_door_by_requirement?(key, door)
        end)
    end
  end

  defp door_is_locked?(door) do
    # Check if door is locked
    door.is_locked == true ||
      door.door_type in ["locked", "locked_gate"] ||
      Map.get(door.properties || %{}, "locked", false)
  end

  defp key_matches_door_by_requirement?(key, door) do
    # Match key to door based on the door's key_required field
    cond do
      # Direct match with key_required field
      door.key_required && door.key_required == key.name ->
        true

      # Check if door properties specify required key
      door.properties && Map.get(door.properties, "required_key") == key.name ->
        true

      # Fallback to name-based matching for backwards compatibility
      key_matches_door_by_name?(key, door) ->
        true

      true ->
        false
    end
  end

  defp key_matches_door_by_name?(key, door) do
    # Match key to door based on name patterns or properties
    key_name_lower = String.downcase(key.name)
    door_name_lower = String.downcase(door.name || "")

    # Check specific location matches first
    location_match?(key_name_lower, door_name_lower) ||
      generic_key_door_match?(key_name_lower, door_name_lower)
  end

  defp location_match?(key_name, door_name) do
    ["sewer", "manor", "gate"]
    |> Enum.any?(fn location ->
      String.contains?(key_name, location) && String.contains?(door_name, location)
    end)
  end

  defp generic_key_door_match?(key_name, door_name) do
    String.contains?(key_name, "key") && String.contains?(door_name, "door")
  end

  defp unlock_doors_with_key(game_state, doors, key) do
    case doors do
      [] ->
        response = ["There are no locked doors here that #{key.name} can unlock."]
        {response, game_state}

      [door | _] ->
        # Unlock the first matching door and its return door
        case unlock_door_and_return_door(door) do
          {:ok, _updated_door} ->
            # Remove the key from inventory after successful use
            updated_game_state = remove_key_from_inventory(game_state, key)

            response = [
              "You use #{key.name}.",
              "The door to the #{door.direction} unlocks with a satisfying click!",
              "You hear another lock click in the distance."
            ]

            {response, updated_game_state}

          {:error, _reason} ->
            response = [
              "You try to use #{key.name}, but it doesn't seem to work.",
              "The door remains locked."
            ]

            {response, game_state}
        end
    end
  end

  defp unlock_door_and_return_door(door) do
    attrs = %{is_locked: false}

    with {:ok, updated_door} <- Shard.Map.update_door(door, attrs) do
      unlock_return_door_if_exists(door, updated_door, attrs)
    end
  end

  defp unlock_return_door_if_exists(door, updated_door, attrs) do
    case Shard.Map.get_return_door(door) do
      nil ->
        {:ok, updated_door}

      return_door ->
        # Always succeed even if return door update fails
        Shard.Map.update_door(return_door, attrs)
        {:ok, updated_door}
    end
  end

  defp remove_key_from_inventory(game_state, key) do
    case Map.get(key, :inventory_id) do
      nil ->
        # Fallback: remove from local state if no inventory_id
        updated_inventory =
          Enum.reject(game_state.inventory_items, fn inv_item ->
            inv_item.id == key.id
          end)

        %{game_state | inventory_items: updated_inventory}

      inventory_id ->
        # Remove from database
        case Shard.Items.remove_item_from_inventory(inventory_id, 1) do
          {:ok, _} ->
            # Reload inventory from database
            updated_inventory =
              ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)

            %{game_state | inventory_items: updated_inventory}

          {:error, _} ->
            # Fallback to local removal if database operation fails
            updated_inventory =
              Enum.reject(game_state.inventory_items, fn inv_item ->
                inv_item.id == key.id
              end)

            %{game_state | inventory_items: updated_inventory}
        end
    end
  end
end
