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
    room_items = get_room_items_at_location(location_string)
    target_item = find_item_by_name(room_items, item_name)

    handle_pickup_attempt(target_item, room_items, item_name, game_state)
  end

  # Get room items at a specific location
  defp get_room_items_at_location(location_string) do
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
  end

  # Find an item by name (case-insensitive)
  defp find_item_by_name(room_items, item_name) do
    Enum.find(room_items, fn item ->
      String.downcase(item.name || "") == String.downcase(item_name)
    end)
  end

  # Handle the pickup attempt based on whether item was found
  defp handle_pickup_attempt(nil, room_items, item_name, game_state) do
    handle_item_not_found(room_items, item_name, game_state)
  end

  defp handle_pickup_attempt(item, _room_items, _item_name, game_state) do
    if item.pickup do
      perform_pickup(item, game_state)
    else
      response = ["You cannot pick up #{item.name}."]
      {response, game_state}
    end
  end

  # Handle case when item is not found
  defp handle_item_not_found(room_items, item_name, game_state) do
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
  end

  # Perform the actual pickup based on item type
  defp perform_pickup(item, game_state) do
    case item.room_item_id do
      nil -> pickup_direct_item(item, game_state)
      room_item_id -> pickup_room_item(item, room_item_id, game_state)
    end
  end

  # Handle pickup of direct items from Item table
  defp pickup_direct_item(item, game_state) do
    case Shard.Items.add_item_to_inventory(game_state.character.id, item.item_id, 1) do
      {:ok, _} -> deactivate_item_and_update_inventory(item, game_state)
      {:error, reason} -> handle_pickup_error(item, reason, game_state)
    end
  end

  # Handle pickup of room items
  defp pickup_room_item(item, room_item_id, game_state) do
    case Shard.Items.pick_up_item(game_state.character.id, room_item_id) do
      {:ok, _} ->
        update_inventory_after_pickup(item, game_state)

      {:error, :item_not_pickupable} ->
        {["You cannot pick up #{item.name}."], game_state}

      {:error, :insufficient_quantity} ->
        {["There isn't enough #{item.name} here to pick up."], game_state}

      {:error, _reason} ->
        {["You failed to pick up #{item.name}."], game_state}
    end
  end

  # Deactivate item and update inventory
  defp deactivate_item_and_update_inventory(item, game_state) do
    item_struct = Shard.Items.get_item!(item.item_id)

    case Shard.Items.update_item(item_struct, %{is_active: false}) do
      {:ok, _} ->
        update_inventory_after_pickup(item, game_state)

      {:error, _reason} ->
        {["You failed to pick up #{item.name} - could not remove from world."], game_state}
    end
  end

  # Update inventory and return success response
  defp update_inventory_after_pickup(item, game_state) do
    updated_inventory = Shard.Items.get_character_inventory(game_state.character.id)
    updated_game_state = %{game_state | inventory_items: updated_inventory}

    response = [
      "You pick up #{item.name}.",
      "#{item.name} has been added to your inventory."
    ]

    {response, updated_game_state}
  end

  # Handle pickup errors
  defp handle_pickup_error(item, reason, game_state) do
    response = ["You failed to pick up #{item.name}. Error: #{inspect(reason)}"]
    {response, game_state}
  end
end
