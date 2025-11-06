defmodule ShardWeb.UserLive.CommandParsers do
  alias Shard.Map, as: GameMap
  alias Shard.Items.Item
  alias Shard.Repo
  import Ecto.Query

  # Parse talk command to extract NPC name
  def parse_talk_command(command) do
    # Match patterns like: talk "npc name", talk 'npc name', talk npc_name
    if Regex.match?(~r/^talk\s+["'](.+)["']\s*$/i, command) do
      case Regex.run(~r/^talk\s+["'](.+)["']\s*$/i, command) do
        [_, npc_name] -> {:ok, String.trim(npc_name)}
        _ -> :error
      end
    else if Regex.match?(~r/^talk\s+(\w+)\s*$/i, command) do
      case Regex.run(~r/^talk\s+(\w+)\s*$/i, command) do
        [_, npc_name] -> {:ok, String.trim(npc_name)}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse quest command to extract NPC name
  def parse_quest_command(command) do
    # Match patterns like: quest "npc name", quest 'npc name', quest npc_name
    if Regex.match?(~r/^quest\s+["'](.+)["']\s*$/i, command) do
      case Regex.run(~r/^quest\s+["'](.+)["']\s*$/i, command) do
        [_, npc_name] -> {:ok, String.trim(npc_name)}
        _ -> :error
      end
    else if Regex.match?(~r/^quest\s+(\w+)\s*$/i, command) do
      case Regex.run(~r/^quest\s+(\w+)\s*$/i, command) do
        [_, npc_name] -> {:ok, String.trim(npc_name)}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse deliver_quest command to extract NPC name
  def parse_deliver_quest_command(command) do
    # Match patterns like: deliver_quest "npc name", deliver_quest 'npc name', deliver_quest npc_name
    if Regex.match?(~r/^deliver_quest\s+["'](.+)["']\s*$/i, command) do
      case Regex.run(~r/^deliver_quest\s+["'](.+)["']\s*$/i, command) do
        [_, npc_name] -> {:ok, String.trim(npc_name)}
        _ -> :error
      end
    else if Regex.match?(~r/^deliver_quest\s+(\w+)\s*$/i, command) do
      case Regex.run(~r/^deliver_quest\s+(\w+)\s*$/i, command) do
        [_, npc_name] -> {:ok, String.trim(npc_name)}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse unlock command to extract direction and item name
  def parse_unlock_command(command) do
    # Match patterns like: unlock north with "key name", unlock east with key_name
    if Regex.match?(~r/^unlock\s+(\w+)\s+with\s+["'](.+)["']\s*$/i, command) do
      case Regex.run(~r/^unlock\s+(\w+)\s+with\s+["'](.+)["']\s*$/i, command) do
        [_, direction, item_name] -> {:ok, String.trim(direction), String.trim(item_name)}
        _ -> :error
      end
    else if Regex.match?(~r/^unlock\s+(\w+)\s+with\s+(\w+)\s*$/i, command) do
      case Regex.run(~r/^unlock\s+(\w+)\s+with\s+(\w+)\s*$/i, command) do
        [_, direction, item_name] -> {:ok, String.trim(direction), String.trim(item_name)}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse pickup command to extract item name
  def parse_pickup_command(command) do
    # Match patterns like: pickup "item name", pickup 'item name', pickup item_name
    if Regex.match?(~r/^pickup\s+["'](.+)["']\s*$/i, command) do
      case Regex.run(~r/^pickup\s+["'](.+)["']\s*$/i, command) do
        [_, item_name] -> {:ok, String.trim(item_name)}
        _ -> :error
      end
    else if Regex.match?(~r/^pickup\s+(\w+)\s*$/i, command) do
      case Regex.run(~r/^pickup\s+(\w+)\s*$/i, command) do
        [_, item_name] -> {:ok, String.trim(item_name)}
        _ -> :error
      end
    else
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
    items_here = get_items_at_location(x, y, game_state.map_id)

    # Find the item by name (case-insensitive)
    target_item =
      Enum.find(items_here, fn item ->
        String.downcase(item.name || "") == String.downcase(item_name)
      end)

    case target_item do
      nil ->
        if length(items_here) > 0 do
          available_names = Enum.map_join(items_here, ", ", & &1.name)

          response = [
            "There is no item named '#{item_name}' here.",
            "Available items: #{available_names}"
          ]

          {response, game_state}
        else
          {["There are no items here to pick up."], game_state}
        end

      item ->
        # Check if item can be picked up (assuming all items can be picked up for now)
        # In the future, you might want to add a "pickupable" field to items

        # Add item to player's inventory
        updated_inventory = [
          %{
            id: item[:id],
            name: item.name,
            type: item.item_type || "misc",
            quantity: item.quantity || 1,
            damage: item[:damage],
            defense: item[:defense],
            effect: item[:effect],
            description: item[:description]
          }
          | game_state.inventory_items
        ]

        # Remove item from the room (this would need database implementation)
        # For now, we'll just update the game state

        response = [
          "You pick up #{item.name}.",
          "#{item.name} has been added to your inventory."
        ]

        updated_game_state = %{game_state | inventory_items: updated_inventory}

        # Remove item from database room/location
        # This would require calling something like:
        # Shard.Items.remove_item_from_location(item.id, "#{x},#{y},0")

        {response, updated_game_state}
    end
  end

  # Execute unlock command with direction and item name
  def execute_unlock_command(game_state, direction, item_name) do
    if has_item_in_inventory?(game_state.inventory_items, item_name) do
      unlock_door_with_item(game_state, direction, item_name)
    else
      {["You don't have '#{item_name}' in your inventory."], game_state}
    end
  end

  # Check if player has the item in inventory
  defp has_item_in_inventory?(inventory_items, item_name) do
    Enum.any?(inventory_items, fn inv_item ->
      String.downcase(inv_item.name || "") == String.downcase(item_name)
    end)
  end

  # Handle unlocking door with item
  defp unlock_door_with_item(game_state, direction, item_name) do
    {x, y} = game_state.player_position

    case GameMap.get_room_by_coordinates(game_state.character.current_zone_id, x, y, 0) do
      nil ->
        {["You are not in a valid room."], game_state}

      room ->
        normalized_direction = normalize_direction(direction)
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

  # Remove item from inventory
  defp remove_item_from_inventory(game_state, item_name) do
    updated_inventory =
      Enum.reject(game_state.inventory_items, fn inv_item ->
        String.downcase(inv_item.name || "") == String.downcase(item_name)
      end)

    %{game_state | inventory_items: updated_inventory}
  end

  # Get items at a specific location
  defp get_items_at_location(x, y, map_id) do
    alias Shard.Items.RoomItem
    location_string = "#{x},#{y},0"

    # Get items from RoomItem table (items placed in world)
    room_items =
      from(ri in RoomItem,
        where: ri.location == ^location_string,
        join: i in Item,
        on: ri.item_id == i.id,
        where: is_nil(i.is_active) or i.is_active == true,
        select: %{
          name: i.name,
          description: i.description,
          item_type: i.item_type,
          quantity: ri.quantity
        }
      )
      |> Repo.all()

    # Also check for items directly in Item table with matching location and map
    direct_items =
      from(i in Item,
        where:
          i.location == ^location_string and
            (i.map == ^map_id or is_nil(i.map)) and
            (is_nil(i.is_active) or i.is_active == true),
        select: %{
          name: i.name,
          description: i.description,
          item_type: i.item_type,
          quantity: 1
        }
      )
      |> Repo.all()

    # Combine both results and remove duplicates based on name
    all_items = room_items ++ direct_items
    all_items |> Enum.uniq_by(& &1.name)
  end
end
