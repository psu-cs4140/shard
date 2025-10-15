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
      # Match unlock [direction] with "item name" or unlock [direction] with 'item name'
      Regex.match?(~r/^unlock\s+(\w+)\s+with\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^unlock\s+(\w+)\s+with\s+["'](.+)["']\s*$/i, command) do
          [_, direction, item_name] -> {:ok, String.trim(direction), String.trim(item_name)}
          _ -> :error
        end

      # Match unlock [direction] with item_name (single word, no quotes)
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
          available_names = Enum.map(items_here, & &1.name) |> Enum.join(", ")

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

        # TODO: Remove item from database room/location
        # This would require calling something like:
        # Shard.Items.remove_item_from_location(item.id, "#{x},#{y},0")

        {response, updated_game_state}
    end
  end

  # Execute unlock command with direction and item name
  def execute_unlock_command(game_state, direction, item_name) do
    {x, y} = game_state.player_position

    # Check if player has the item in inventory
    has_item =
      Enum.any?(game_state.inventory_items, fn inv_item ->
        String.downcase(inv_item.name || "") == String.downcase(item_name)
      end)

    if not has_item do
      {["You don't have '#{item_name}' in your inventory."], game_state}
    else
      # Get current room
      case GameMap.get_room_by_coordinates(x, y) do
        nil ->
          {["You are not in a valid room."], game_state}

        room ->
          # Normalize direction name
          normalized_direction =
            case String.downcase(direction) do
              dir when dir in ["n", "north"] -> "north"
              dir when dir in ["s", "south"] -> "south"
              dir when dir in ["e", "east"] -> "east"
              dir when dir in ["w", "west"] -> "west"
              dir when dir in ["ne", "northeast"] -> "northeast"
              dir when dir in ["se", "southeast"] -> "southeast"
              dir when dir in ["nw", "northwest"] -> "northwest"
              dir when dir in ["sw", "southwest"] -> "southwest"
              other -> other
            end

          # Check if there's a door in that direction
          door = GameMap.get_door_in_direction(room.id, normalized_direction)

          case door do
            nil ->
              {["There is no door to the #{normalized_direction}."], game_state}

            door ->
              cond do
                not door.is_locked ->
                  {["The door to the #{normalized_direction} is already unlocked."], game_state}

                door.key_required == nil or door.key_required == "" ->
                  {[
                     "The door to the #{normalized_direction} is locked but doesn't require a specific key."
                   ], game_state}

                String.downcase(door.key_required) == String.downcase(item_name) ->
                  # Unlock the door
                  case GameMap.update_door(door, %{is_locked: false}) do
                    {:ok, _updated_door} ->
                      # Also unlock the return door if it exists
                      return_door = GameMap.get_return_door(door)

                      if return_door do
                        GameMap.update_door(return_door, %{is_locked: false})
                      end

                      {[
                         "You use the #{item_name} to unlock the door to the #{normalized_direction}.",
                         "The door is now unlocked!"
                       ], game_state}

                    {:error, _changeset} ->
                      {["Failed to unlock the door. Something went wrong."], game_state}
                  end

                true ->
                  {[
                     "The #{item_name} doesn't fit this lock. This door requires: #{door.key_required}"
                   ], game_state}
              end
          end
      end
    end
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
