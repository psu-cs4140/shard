defmodule ShardWeb.UserLive.CommandParsers do
  alias Shard.Map, as: GameMap
  alias Shard.Items.Item
  alias Shard.Repo
  import Ecto.Query

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
            updated_inventory = ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)
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

  # Check if player has the item in inventory using database
  defp has_item_in_inventory?(inventory_items, item_name) do
    # First check the loaded inventory items
    has_in_loaded = Enum.any?(inventory_items, fn inv_item ->
      String.downcase(inv_item.name || "") == String.downcase(item_name)
    end)
    
    # Also check database directly to ensure accuracy
    if has_in_loaded do
      true
    else
      # Get character_id from the first inventory item if available
      case inventory_items do
        [first_item | _] when is_map(first_item) ->
          # This is a fallback - ideally we'd pass character_id directly
          false
        _ ->
          false
      end
    end
  end

  # Handle unlocking door with item
  defp unlock_door_with_item(game_state, direction, item_name) do
    # Check if character has the item using database function
    if Shard.Items.character_has_item?(game_state.character.id, item_name) do
      {x, y} = game_state.player_position

      case GameMap.get_room_by_coordinates(game_state.character.current_zone_id, x, y, 0) do
        nil ->
          {["You are not in a valid room."], game_state}

        room ->
          normalized_direction = normalize_direction(direction)
          door = GameMap.get_door_in_direction(room.id, normalized_direction)
          handle_door_unlock(game_state, door, normalized_direction, item_name)
      end
    else
      {["You don't have '#{item_name}' in your inventory."], game_state}
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

  # Validate door state and unlock if possible
  defp validate_and_unlock_door(game_state, door, normalized_direction, item_name) do
    cond do
      not door.is_locked ->
        {["The door to the #{normalized_direction} is already unlocked."], game_state}

      door.key_required == nil or door.key_required == "" ->
        {[
           "The door to the #{normalized_direction} is locked but doesn't require a specific key."
         ], game_state}

      String.downcase(door.key_required) == String.downcase(item_name) ->
        perform_door_unlock(game_state, door, normalized_direction, item_name)

      true ->
        {[
           "The #{item_name} doesn't fit this lock. This door requires: #{door.key_required}"
         ], game_state}
    end
  end

  # Perform the actual door unlock operation
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

  # Unlock the return door if it exists
  defp unlock_return_door(door) do
    return_door = GameMap.get_return_door(door)

    if return_door do
      GameMap.update_door(return_door, %{is_locked: false})
    end
  end

  # Remove item from inventory using database
  defp remove_item_from_inventory(game_state, item_name) do
    # Find the inventory item to remove
    inventory_item = Enum.find(game_state.inventory_items, fn inv_item ->
      String.downcase(inv_item.name || "") == String.downcase(item_name)
    end)

    case inventory_item do
      nil ->
        game_state

      item ->
        # Use database function to remove the item
        case Map.get(item, :inventory_id) do
          nil ->
            # Fallback: just remove from local state if no inventory_id
            updated_inventory = Enum.reject(game_state.inventory_items, fn inv_item ->
              String.downcase(inv_item.name || "") == String.downcase(item_name)
            end)
            %{game_state | inventory_items: updated_inventory}

          inventory_id ->
            # Remove from database
            case Shard.Items.remove_item_from_inventory(inventory_id, 1) do
              {:ok, _} ->
                # Reload inventory from database
                updated_inventory = ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)
                %{game_state | inventory_items: updated_inventory}

              {:error, _} ->
                # Fallback to local removal if database operation fails
                updated_inventory = Enum.reject(game_state.inventory_items, fn inv_item ->
                  String.downcase(inv_item.name || "") == String.downcase(item_name)
                end)
                %{game_state | inventory_items: updated_inventory}
            end
        end
    end
  end

  # Get items at a specific location using the Items context
  defp get_items_at_location(x, y, _map_id) do
    location_string = "#{x},#{y},0"
    
    # Use the proper Items context function
    room_items = Shard.Items.get_room_items(location_string)
    
    # Transform to the format expected by the rest of the code
    Enum.map(room_items, fn room_item ->
      %{
        id: room_item.id,
        name: room_item.item.name,
        description: room_item.item.description,
        item_type: room_item.item.item_type,
        quantity: room_item.quantity
      }
    end)
  end
end
