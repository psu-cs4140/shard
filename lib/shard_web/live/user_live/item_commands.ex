defmodule ShardWeb.UserLive.ItemCommands do
  @moduledoc """
  Item-related command functions for the user live view.
  """

  alias Shard.Items.{Item, RoomItem}
  alias Shard.Repo
  import Ecto.Query

  # Get items at a specific location
  def get_items_at_location(x, y, _zone_id) do
    location_string = "#{x},#{y},0"

    # Get items from RoomItem table (items placed in world)
    room_items =
      from(ri in RoomItem,
        where: ri.location == ^location_string,
        join: i in Item,
        on: ri.item_id == i.id,
        where: is_nil(i.is_active) or i.is_active == true,
        select: %{
          room_item_id: ri.id,
          item_id: i.id,
          name: i.name,
          description: i.description,
          item_type: i.item_type,
          quantity: ri.quantity,
          pickup: i.pickup
        }
      )
      |> Repo.all()

    # Also check for items directly in Item table with matching location
    direct_items =
      from(i in Item,
        where:
          i.location == ^location_string and
            (is_nil(i.is_active) or i.is_active == true),
        select: %{
          room_item_id: nil,
          item_id: i.id,
          name: i.name,
          description: i.description,
          item_type: i.item_type,
          quantity: 1,
          pickup: i.pickup
        }
      )
      |> Repo.all()

    # Combine both results and remove duplicates based on name
    all_items = room_items ++ direct_items
    all_items |> Enum.uniq_by(& &1.name)
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
    location_string = "#{x},#{y},0"

    # Find room items at this location
    room_items =
      from(ri in RoomItem,
        where: ri.location == ^location_string,
        join: i in Item,
        on: ri.item_id == i.id,
        where: is_nil(i.is_active) or i.is_active == true,
        select: %{
          room_item_id: ri.id,
          item_id: i.id,
          name: i.name,
          description: i.description,
          item_type: i.item_type,
          quantity: ri.quantity,
          pickup: i.pickup
        }
      )
      |> Repo.all()

    # Find the item by name (case-insensitive)
    target_room_item =
      Enum.find(room_items, fn item ->
        String.downcase(item.name || "") == String.downcase(item_name)
      end)

    case target_room_item do
      nil ->
        if length(room_items) > 0 do
          # credo:disable-for-next-line Credo.Check.Refactor.EnumMapJoin
          available_names = Enum.map_join(room_items, ", ", & &1.name)

          response = [
            "There is no item named '#{item_name}' here.",
            "Available items: #{available_names}"
          ]

          {response, game_state}
        else
          {["There are no items here to pick up."], game_state}
        end

      item ->
        # Check if item can be picked up
        if item.pickup do
          # Handle pickup differently for room items vs direct items
          case item.room_item_id do
            nil ->
              # This is a direct item from the Item table
              case Shard.Items.add_item_to_inventory(game_state.character.id, item.item_id, 1) do
                {:ok, _} ->
                  # Remove the item from the world by setting is_active to false
                  item_struct = Shard.Items.get_item!(item.item_id)

                  case Shard.Items.update_item(item_struct, %{is_active: false}) do
                    {:ok, _} ->
                      # Reload the character's inventory to reflect the change
                      updated_inventory =
                        Shard.Items.get_character_inventory(game_state.character.id)

                      updated_game_state = %{game_state | inventory_items: updated_inventory}

                      response = [
                        "You pick up #{item.name}.",
                        "#{item.name} has been added to your inventory."
                      ]

                      {response, updated_game_state}

                    {:error, _reason} ->
                      response = [
                        "You failed to pick up #{item.name} - could not remove from world."
                      ]

                      {response, game_state}
                  end

                {:error, reason} ->
                  response = ["You failed to pick up #{item.name}. Error: #{inspect(reason)}"]
                  {response, game_state}
              end

            room_item_id ->
              # This is a room item, use the existing pickup function
              case Shard.Items.pick_up_item(game_state.character.id, room_item_id) do
                {:ok, _} ->
                  # Reload the character's inventory to reflect the change
                  updated_inventory = Shard.Items.get_character_inventory(game_state.character.id)
                  updated_game_state = %{game_state | inventory_items: updated_inventory}

                  response = [
                    "You pick up #{item.name}.",
                    "#{item.name} has been added to your inventory."
                  ]

                  {response, updated_game_state}

                {:error, :item_not_pickupable} ->
                  response = ["You cannot pick up #{item.name}."]
                  {response, game_state}

                {:error, :insufficient_quantity} ->
                  response = ["There isn't enough #{item.name} here to pick up."]
                  {response, game_state}

                {:error, _reason} ->
                  response = ["You failed to pick up #{item.name}."]
                  {response, game_state}
              end
          end
        else
          response = ["You cannot pick up #{item.name}."]
          {response, game_state}
        end
    end
  end
end
