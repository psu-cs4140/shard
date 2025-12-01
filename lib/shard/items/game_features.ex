# credo:disable-for-this-file Credo.Check.Refactor.Nesting
defmodule Shard.Items.GameFeatures do
  @moduledoc """
  Game-specific features for items including room items, hotbar, tutorial items, and quest functionality.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Items.{Item, CharacterInventory, RoomItem, HotbarSlot}

  ## Room Items

  def get_room_items(location) do
    from(ri in RoomItem,
      where: ri.location == ^location,
      preload: [:item]
    )
    |> Repo.all()
  end

  # credo:disable-for-next-line Credo.Check.Refactor.Nesting
  def drop_item_in_room(character_id, inventory_id, location, quantity \\ 1) do
    case Repo.get(CharacterInventory, inventory_id) do
      nil ->
        {:error, :inventory_not_found}

      inventory ->
        inventory = Repo.preload(inventory, :item)

        if inventory.quantity >= quantity do
          Repo.transaction(fn ->
            # Create room item
            case %RoomItem{}
                 |> RoomItem.changeset(%{
                   location: location,
                   item_id: inventory.item_id,
                   quantity: quantity,
                   dropped_by_character_id: character_id
                 })
                 |> Repo.insert() do
              {:ok, room_item} ->
                # Remove from inventory
                case Shard.Items.remove_item_from_inventory(inventory_id, quantity) do
                  {:ok, _} -> room_item
                  error -> Repo.rollback(error)
                end

              {:error, changeset} ->
                Repo.rollback(changeset)
            end
          end)
        else
          {:error, :insufficient_quantity}
        end
    end
  end

  def pick_up_item(character_id, room_item_id, quantity \\ nil) do
    room_item = Repo.get!(RoomItem, room_item_id) |> Repo.preload(:item)
    pickup_quantity = quantity || room_item.quantity

    with :ok <- validate_pickup(room_item, pickup_quantity) do
      execute_pickup_transaction(character_id, room_item, pickup_quantity)
    end
  end

  defp validate_pickup(room_item, pickup_quantity) do
    cond do
      not room_item.item.pickup ->
        {:error, :item_not_pickupable}

      room_item.quantity < pickup_quantity ->
        {:error, :insufficient_quantity}

      true ->
        :ok
    end
  end

  defp execute_pickup_transaction(character_id, room_item, pickup_quantity) do
    Repo.transaction(fn ->
      case Shard.Items.add_item_to_inventory(character_id, room_item.item_id, pickup_quantity) do
        {:ok, _} ->
          case handle_room_item_removal(room_item, pickup_quantity) do
            {:ok, result} -> result
            error -> Repo.rollback(error)
          end

        error ->
          Repo.rollback(error)
      end
    end)
  end

  defp handle_room_item_removal(room_item, pickup_quantity) do
    if room_item.quantity == pickup_quantity do
      remove_entire_room_item(room_item)
    else
      update_room_item_quantity(room_item, pickup_quantity)
    end
  end

  defp remove_entire_room_item(room_item) do
    case Repo.delete(room_item) do
      {:ok, _} -> {:ok, :picked_up}
      error -> Repo.rollback(error)
    end
  end

  defp update_room_item_quantity(room_item, pickup_quantity) do
    case room_item
         |> RoomItem.changeset(%{quantity: room_item.quantity - pickup_quantity})
         |> Repo.update() do
      {:ok, _} -> {:ok, :picked_up}
      error -> Repo.rollback(error)
    end
  end

  ## Hotbar

  def get_character_hotbar(character_id) do
    from(hs in HotbarSlot,
      where: hs.character_id == ^character_id,
      preload: [:item],
      order_by: [asc: :slot_number]
    )
    |> Repo.all()
  end

  def set_hotbar_slot(character_id, slot_number, inventory_id \\ nil) do
    case validate_inventory_for_hotbar(inventory_id) do
      {:ok, inventory} ->
        # Preload the item association to get the item_id
        inventory_with_item = if inventory, do: Repo.preload(inventory, :item), else: nil

        attrs = %{
          character_id: character_id,
          slot_number: slot_number,
          item_id: inventory_with_item && inventory_with_item.item_id,
          inventory_id: inventory_id
        }

        # Use a transaction to ensure consistency
        Repo.transaction(fn ->
          case Repo.get_by(HotbarSlot, character_id: character_id, slot_number: slot_number) do
            nil ->
              case %HotbarSlot{}
                   |> HotbarSlot.changeset(attrs)
                   |> Repo.insert() do
                {:ok, hotbar_slot} -> hotbar_slot
                {:error, changeset} -> Repo.rollback(changeset)
              end

            existing ->
              case existing
                   |> HotbarSlot.changeset(attrs)
                   |> Repo.update() do
                {:ok, hotbar_slot} -> hotbar_slot
                {:error, changeset} -> Repo.rollback(changeset)
              end
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp validate_inventory_for_hotbar(nil), do: {:ok, nil}

  defp validate_inventory_for_hotbar(inventory_id) when is_binary(inventory_id) do
    case Integer.parse(inventory_id) do
      {id, ""} -> validate_inventory_for_hotbar(id)
      _ -> {:error, :invalid_inventory_id}
    end
  end

  defp validate_inventory_for_hotbar(inventory_id) when is_integer(inventory_id) do
    case Repo.get(CharacterInventory, inventory_id) do
      nil ->
        {:error, :inventory_not_found}

      inventory ->
        # Ensure the inventory item has an associated item
        inventory_with_item = Repo.preload(inventory, :item)

        if inventory_with_item.item do
          {:ok, inventory_with_item}
        else
          {:error, :item_not_found}
        end
    end
  end

  defp validate_inventory_for_hotbar(_), do: {:error, :invalid_inventory_id}

  def clear_hotbar_slot(character_id, slot_number) do
    case Repo.get_by(HotbarSlot, character_id: character_id, slot_number: slot_number) do
      nil ->
        # Create an empty hotbar slot to match expected return type
        %HotbarSlot{}
        |> HotbarSlot.changeset(%{
          character_id: character_id,
          slot_number: slot_number,
          item_id: nil,
          inventory_id: nil
        })
        |> Repo.insert()

      hotbar_slot ->
        Repo.delete(hotbar_slot)
    end
  end

  ## Tutorial Items

  def create_tutorial_key do
    alias Shard.Items.{Item, RoomItem}

    case find_existing_tutorial_key() do
      {:ok, item} -> {:ok, item}
      :not_found -> create_new_tutorial_key()
    end
  end

  defp find_existing_tutorial_key do
    alias Shard.Items.{Item, RoomItem}

    existing_key =
      from(ri in RoomItem,
        where: ri.location == "0,2,0",
        join: i in Item,
        on: ri.item_id == i.id,
        where: i.name == "Tutorial Key"
      )
      |> Repo.one()

    case existing_key do
      nil -> :not_found
      key -> get_tutorial_key_item(key.item_id)
    end
  end

  defp get_tutorial_key_item(item_id) do
    case Repo.get(Shard.Items.Item, item_id) do
      nil -> {:error, :item_not_found}
      item -> {:ok, item}
    end
  end

  defp create_new_tutorial_key do
    case find_or_create_tutorial_key_item() do
      {:ok, key_item} -> place_tutorial_key_in_room(key_item)
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp find_or_create_tutorial_key_item do
    case Repo.get_by(Shard.Items.Item, name: "Tutorial Key") do
      nil -> create_tutorial_key_item()
      existing_item -> {:ok, existing_item}
    end
  end

  defp create_tutorial_key_item do
    %Shard.Items.Item{}
    |> Shard.Items.Item.changeset(%{
      name: "Tutorial Key",
      description: "A mysterious key that might unlock something important.",
      item_type: "misc",
      rarity: "common",
      value: 10,
      stackable: false,
      equippable: false,
      location: "0,2,0",
      map: "tutorial_terrain",
      is_active: true
    })
    |> Repo.insert()
  end

  defp place_tutorial_key_in_room(key_item) do
    case %Shard.Items.RoomItem{}
         |> Shard.Items.RoomItem.changeset(%{
           item_id: key_item.id,
           location: "0,2,0",
           quantity: 1
         })
         |> Repo.insert() do
      {:ok, _room_item} -> {:ok, key_item}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def create_dungeon_door do
    alias Shard.Map

    # Ensure rooms exist first, create them if they don't
    {:ok, from_room} = ensure_room_exists(2, 2, 0, "Entrance Hall")
    {:ok, to_room} = ensure_room_exists(2, 1, 0, "Dungeon Entrance")

    # Check if a door already exists and delete it if it does
    existing_door = Map.get_door_in_direction(from_room.id, "north")

    if not is_nil(existing_door) do
      # Delete the existing door (this will also delete the return door)
      case Map.delete_door(existing_door) do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, "Failed to delete existing door: #{inspect(reason)}"}
      end
    end

    # Create the locked door from (2,2) to (2,1) going north
    case Map.create_door(%{
           from_room_id: from_room.id,
           to_room_id: to_room.id,
           direction: "north",
           door_type: "locked_gate",
           is_locked: true,
           key_required: "Tutorial Key",
           name: "Locked Dungeon Gate",
           description:
             "A heavy iron gate that blocks the entrance to the dungeon. It requires a key to open."
         }) do
      {:ok, door} -> {:ok, door}
      {:error, reason} -> {:error, "Failed to create dungeon door: #{inspect(reason)}"}
    end
  end

  defp ensure_room_exists(x, y, z, name) do
    case Shard.Map.get_room_by_coordinates(x, y, z) do
      nil ->
        # Room doesn't exist, create it
        case Shard.Map.create_room(%{
               name: name,
               description: "A room at coordinates (#{x}, #{y}, #{z})",
               x_coordinate: x,
               y_coordinate: y,
               z_coordinate: z,
               room_type: "standard",
               is_public: true
             }) do
          {:ok, room} -> {:ok, room}
          {:error, changeset} -> {:error, "Failed to create room: #{inspect(changeset.errors)}"}
        end

      room ->
        # Room already exists
        {:ok, room}
    end
  end

  @doc """
  Checks if a character has the required items for quest objectives.

  ## Examples

      iex> character_has_quest_items?(character_id, %{"retrieve_items" => [%{"item_name" => "Tutorial Key", "quantity" => 1}]})
      true

      iex> character_has_quest_items?(character_id, %{"retrieve_items" => [%{"item_name" => "Missing Item", "quantity" => 1}]})
      false

  """
  def character_has_quest_items?(character_id, objectives) when is_map(objectives) do
    case objectives do
      %{"retrieve_items" => items} when is_list(items) ->
        Enum.all?(items, fn item ->
          required_quantity = Map.get(item, "quantity", 1)

          actual_quantity =
            Shard.Items.get_character_item_quantity(character_id, item["item_name"])

          actual_quantity >= required_quantity
        end)

      _ ->
        # No retrieve_items objective, so consider it satisfied
        true
    end
  end

  def character_has_quest_items?(_character_id, _objectives), do: true

  @doc """
  Checks if a character has the tutorial key in their inventory.

  ## Examples

      iex> has_tutorial_key?(character_id)
      true

      iex> has_tutorial_key?(character_id)
      false

  """
  def has_tutorial_key?(character_id) do
    Shard.Items.character_has_item?(character_id, "Tutorial Key")
  end

  @doc """
  Checks if a character has access to the dungeon door (this is a placeholder function).
  In a real implementation, this might check if the character has unlocked a specific door
  or has the required key/permission.

  ## Examples

      iex> has_dungeon_door?(character_id)
      false

  """
  def has_dungeon_door?(_character_id) do
    # This is a placeholder implementation
    # In a real game, this might check if the character has unlocked the dungeon door
    # or has the required permissions/items to access it
    false
  end
end
