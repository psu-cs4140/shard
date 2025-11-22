defmodule ShardWeb.UserLive.CommandParsers do
  alias Shard.Map, as: GameMap

  # Parse talk command to extract NPC name
  def parse_talk_command(command) do
    # Match patterns like: talk "npc name", talk 'npc name', talk npc_name
    cond do
      # Match talk "npc name" or talk 'npc name'
      Regex.match?(~r/^talk\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^talk\s+["'](.+)["']\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      # Match talk npc_name (single word, no quotes)
      Regex.match?(~r/^talk\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^talk\s+(\w+)\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse quest command to extract NPC name
  def parse_quest_command(command) do
    # Match patterns like: quest "npc name", quest 'npc name', quest npc_name
    cond do
      # Match quest "npc name" or quest 'npc name'
      Regex.match?(~r/^quest\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^quest\s+["'](.+)["']\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      # Match quest npc_name (single word, no quotes)
      Regex.match?(~r/^quest\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^quest\s+(\w+)\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse deliver_quest command to extract NPC name
  def parse_deliver_quest_command(command) do
    # Match patterns like: deliver_quest "npc name", deliver_quest 'npc name', deliver_quest npc_name
    cond do
      # Match deliver_quest "npc name" or deliver_quest 'npc name'
      Regex.match?(~r/^deliver_quest\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^deliver_quest\s+["'](.+)["']\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      # Match deliver_quest npc_name (single word, no quotes)
      Regex.match?(~r/^deliver_quest\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^deliver_quest\s+(\w+)\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse unlock command to extract direction and item name
  def parse_unlock_command(command) do
    # Match patterns like: unlock north with "key name", unlock east with key_name
    cond do
      Regex.match?(~r/^unlock\s+(\w+)\s+with\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^unlock\s+(\w+)\s+with\s+["'](.+)["']\s*$/i, command) do
          [_, direction, item_name] -> {:ok, String.trim(direction), String.trim(item_name)}
          _ -> :error
        end

      Regex.match?(~r/^unlock\s+(\w+)\s+with\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^unlock\s+(\w+)\s+with\s+(\w+)\s*$/i, command) do
          [_, direction, item_name] -> {:ok, String.trim(direction), String.trim(item_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse pickup command to extract item name
  def parse_pickup_command(command) do
    # Match patterns like: pickup "item name", pickup 'item name', pickup item_name
    cond do
      # Match pickup "item name" or pickup 'item name'
      Regex.match?(~r/^pickup\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^pickup\s+["'](.+)["']\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      # Match pickup item_name (single word, no quotes)
      Regex.match?(~r/^pickup\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^pickup\s+(\w+)\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse equipped command to show equipped items
  def parse_equipped_command(command) do
    # Match patterns like: equipped
    if Regex.match?(~r/^equipped\s*$/i, command) do
      :ok
    else
      :error
    end
  end

  # Parse equip command to extract item name
  def parse_equip_command(command) do
    # Match patterns like: equip "item name", equip 'item name', equip item_name
    cond do
      # Match equip "item name" or equip 'item name'
      Regex.match?(~r/^equip\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^equip\s+["'](.+)["']\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      # Match equip item_name (single word, no quotes)
      Regex.match?(~r/^equip\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^equip\s+(\w+)\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse unequip command to extract item name
  def parse_unequip_command(command) do
    # Match patterns like: unequip "item name", unequip 'item name', unequip item_name
    cond do
      # Match unequip "item name" or unequip 'item name'
      Regex.match?(~r/^unequip\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^unequip\s+["'](.+)["']\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      # Match unequip item_name (single word, no quotes)
      Regex.match?(~r/^unequip\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^unequip\s+(\w+)\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse accept_quest command to extract NPC name and quest title
  def parse_accept_quest_command(command) do
    # Match pattern: accept_quest "npc name" "quest title"
    case Regex.run(~r/^accept_quest\s+"([^"]+)"\s+"([^"]+)"\s*$/i, command) do
      [_, npc_name, quest_title] -> {:ok, String.trim(npc_name), String.trim(quest_title)}
      _ -> :error
    end
  end

  # Parse create room command: "create room <direction>"
  def parse_create_room_command(command) do
    # Match patterns like: create room north, create room "north"
    if Regex.match?(~r/^create\s+room\s+["']?(\w+)["']?\s*$/i, command) do
      case Regex.run(~r/^create\s+room\s+["']?(\w+)["']?\s*$/i, command) do
        [_, direction] -> {:ok, String.trim(direction) |> String.downcase()}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse delete room command: "delete room <direction>"
  def parse_delete_room_command(command) do
    # Match patterns like: delete room north, delete room "north"
    if Regex.match?(~r/^delete\s+room\s+["']?(\w+)["']?\s*$/i, command) do
      case Regex.run(~r/^delete\s+room\s+["']?(\w+)["']?\s*$/i, command) do
        [_, direction] -> {:ok, String.trim(direction) |> String.downcase()}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse create door command: "create door <direction>"
  def parse_create_door_command(command) do
    # Match patterns like: create door north, create door "north"
    if Regex.match?(~r/^create\s+door\s+["']?(\w+)["']?\s*$/i, command) do
      case Regex.run(~r/^create\s+door\s+["']?(\w+)["']?\s*$/i, command) do
        [_, direction] -> {:ok, String.trim(direction) |> String.downcase()}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse delete door command: "delete door <direction>"
  def parse_delete_door_command(command) do
    # Match patterns like: delete door north, delete door "north"
    if Regex.match?(~r/^delete\s+door\s+["']?(\w+)["']?\s*$/i, command) do
      case Regex.run(~r/^delete\s+door\s+["']?(\w+)["']?\s*$/i, command) do
        [_, direction] -> {:ok, String.trim(direction) |> String.downcase()}
        _ -> :error
      end
    else
      :error
    end
  end

  # Execute pickup command with a specific item name
  def execute_pickup_command(game_state, item_name) do
    {x, y} = game_state.player_position
    location_string = "#{x},#{y},0"

    # Get room items from database
    room_items = Shard.Items.get_room_items(location_string)

    # Find the item by name (case-insensitive)
    target_room_item =
      Enum.find(room_items, fn room_item ->
        String.downcase(room_item.item.name || "") == String.downcase(item_name)
      end)

    case target_room_item do
      nil ->
        if length(room_items) > 0 do
          available_names = Enum.map_join(room_items, ", ", & &1.item.name)

          response = [
            "There is no item named '#{item_name}' here.",
            "Available items: #{available_names}"
          ]

          {response, game_state}
        else
          {["There are no items here to pick up."], game_state}
        end

      room_item ->
        # Use the proper database function to pick up the item
        case Shard.Items.pick_up_item(game_state.character.id, room_item.id, room_item.quantity) do
          {:ok, _result} ->
            # Reload inventory from database to sync with game state
            updated_inventory =
              ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)

            updated_game_state = %{game_state | inventory_items: updated_inventory}

            response = [
              "You pick up #{room_item.item.name}.",
              "#{room_item.item.name} has been added to your inventory."
            ]

            {response, updated_game_state}

          {:error, :item_not_pickupable} ->
            {["You cannot pick up #{room_item.item.name}."], game_state}

          {:error, :insufficient_quantity} ->
            {["There isn't enough #{room_item.item.name} here to pick up."], game_state}

          {:error, _reason} ->
            {["Failed to pick up #{room_item.item.name}."], game_state}
        end
    end
  end

  # Execute unlock command with direction and item name
  def execute_unlock_command(game_state, direction, item_name) do
    unlock_door_with_item(game_state, direction, item_name)
  end

  # Main unlock door logic
  defp unlock_door_with_item(game_state, direction, item_name) do
    normalized_direction = normalize_direction(direction)
    {x, y} = game_state.player_position

    # Get the current room first, then find the door in the specified direction
    case GameMap.get_room_by_coordinates_legacy(x, y, 0) do
      nil ->
        handle_door_unlock(game_state, nil, normalized_direction, item_name)

      room ->
        door = GameMap.get_door_in_direction(room.id, normalized_direction)
        handle_door_unlock(game_state, door, normalized_direction, item_name)
    end
  end

  # Normalize direction name
  defp normalize_direction(direction) do
    direction_map = %{
      "n" => "north",
      "north" => "north",
      "s" => "south",
      "south" => "south",
      "e" => "east",
      "east" => "east",
      "w" => "west",
      "west" => "west",
      "ne" => "northeast",
      "northeast" => "northeast",
      "se" => "southeast",
      "southeast" => "southeast",
      "nw" => "northwest",
      "northwest" => "northwest",
      "sw" => "southwest",
      "southwest" => "southwest"
    }

    downcased_direction = String.downcase(direction)
    Map.get(direction_map, downcased_direction, direction)
  end

  # Handle door unlock logic
  defp handle_door_unlock(game_state, door, normalized_direction, item_name) do
    case door do
      nil ->
        {["There is no door to the #{normalized_direction}."], game_state}

      door ->
        validate_and_unlock_door(game_state, door, normalized_direction, item_name)
    end
  end

  # Validate door state and player inventory before unlocking
  defp validate_and_unlock_door(game_state, door, normalized_direction, item_name) do
    cond do
      !door.is_locked ->
        {["The door to the #{normalized_direction} is already unlocked."], game_state}

      !player_has_item?(game_state, item_name) ->
        {["You don't have a #{item_name} in your inventory."], game_state}

      true ->
        perform_door_unlock(game_state, door, normalized_direction, item_name)
    end
  end

  # Check if player has the specified item in inventory
  defp player_has_item?(game_state, item_name) do
    Enum.any?(game_state.inventory_items, fn inventory_item ->
      String.downcase(inventory_item.item.name || "") == String.downcase(item_name)
    end)
  end

  defp perform_door_unlock(game_state, door, normalized_direction, item_name) do
    case GameMap.update_door(door, %{is_locked: false}) do
      {:ok, _updated_door} ->
        unlock_return_door(door)
        updated_game_state = remove_item_from_inventory(game_state, item_name)

        {[
           "You use the #{item_name} to unlock the door to the #{normalized_direction}.",
           "The #{item_name} is consumed in the process.",
           "The door is now unlocked!"
         ], updated_game_state}

      {:error, _changeset} ->
        {["Failed to unlock the door. Something went wrong."], game_state}
    end
  end

  # Unlock the corresponding return door if it exists
  defp unlock_return_door(door) do
    # Find the return door (door going back from the destination room)
    case GameMap.get_return_door(door) do
      # No return door exists
      nil ->
        :ok

      return_door ->
        GameMap.update_door(return_door, %{is_locked: false})
        :ok
    end
  end

  # Execute equipped command to show equipped items
  def execute_equipped_command(game_state) do
    # Get all available equipment slots
    all_slots = Shard.Items.Item.equipment_slots()

    # Use the same data source as the inventory management page
    inventory_items = Shard.Items.get_character_inventory(game_state.character.id)

    # Filter for equipped items only
    equipped_items = Enum.filter(inventory_items, fn inv_item -> inv_item.equipped end)

    # Create a map of slot -> item name for equipped items
    equipped_map =
      Enum.reduce(equipped_items, %{}, fn inv_item, acc ->
        slot = inv_item.equipment_slot || "unknown"
        Map.put(acc, slot, inv_item.item.name)
      end)

    # Build response showing all slots
    response =
      ["Your equipment slots:"] ++
        Enum.map(all_slots, fn slot ->
          item_name = Map.get(equipped_map, slot, "None")
          "  #{String.capitalize(slot)}: #{item_name}"
        end)

    {response, game_state}
  end

  # Execute equip command with a specific item name
  def execute_equip_command(game_state, item_name) do
    # Get character's inventory
    inventory_items = Shard.Items.get_character_inventory(game_state.character.id)

    # Find the item by name (case-insensitive)
    target_item =
      Enum.find(inventory_items, fn inv_item ->
        String.downcase(inv_item.item.name || "") == String.downcase(item_name)
      end)

    case target_item do
      nil ->
        {["You don't have an item named '#{item_name}' in your inventory."], game_state}

      inv_item ->
        if inv_item.equipped do
          {["#{inv_item.item.name} is already equipped."], game_state}
        else
          case Shard.Items.equip_item(inv_item.id) do
            {:ok, _} ->
              # Reload inventory to sync with game state
              updated_inventory =
                ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)

              updated_game_state = %{game_state | inventory_items: updated_inventory}

              {["You equip #{inv_item.item.name}."], updated_game_state}

            {:error, :not_equippable} ->
              {["#{inv_item.item.name} cannot be equipped."], game_state}

            {:error, :already_equipped} ->
              {["#{inv_item.item.name} is already equipped."], game_state}

            {:error, reason} ->
              {["Failed to equip #{inv_item.item.name}: #{reason}"], game_state}
          end
        end
    end
  end

  # Execute unequip command with a specific item name
  def execute_unequip_command(game_state, item_name) do
    # Get character's inventory
    inventory_items = Shard.Items.get_character_inventory(game_state.character.id)

    # Find the equipped item by name (case-insensitive)
    target_item =
      Enum.find(inventory_items, fn inv_item ->
        inv_item.equipped &&
          String.downcase(inv_item.item.name || "") == String.downcase(item_name)
      end)

    case target_item do
      nil ->
        {["You don't have an equipped item named '#{item_name}'."], game_state}

      inv_item ->
        case Shard.Items.unequip_item(inv_item.id) do
          {:ok, _} ->
            # Reload inventory to sync with game state
            updated_inventory =
              ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)

            updated_game_state = %{game_state | inventory_items: updated_inventory}

            {["You unequip #{inv_item.item.name}."], updated_game_state}

          {:error, reason} ->
            {["Failed to unequip #{inv_item.item.name}: #{reason}"], game_state}
        end
    end
  end

  # Remove item from player's inventory
  defp remove_item_from_inventory(game_state, item_name) do
    # Find the inventory item to remove
    inventory_item =
      Enum.find(game_state.inventory_items, fn inv_item ->
        String.downcase(inv_item.item.name || "") == String.downcase(item_name)
      end)

    case inventory_item do
      nil ->
        # Item not found, return unchanged state
        game_state

      inv_item ->
        # Remove one quantity of the item
        case Shard.Items.remove_item_from_inventory(inv_item.id, 1) do
          {:ok, _} ->
            # Reload inventory from database to sync with game state
            updated_inventory =
              ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)

            %{game_state | inventory_items: updated_inventory}

          {:error, _} ->
            # Failed to remove, return unchanged state
            game_state
        end
    end
  end
end
