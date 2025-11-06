# credo:disable-for-this-file Credo.Check.Refactor.Nesting
defmodule Shard.Items do
  @moduledoc """
  The Items context.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Items.{Item, CharacterInventory, RoomItem, HotbarSlot}

  ## Items

  def list_items do
    Repo.all(Item)
  end

  def list_active_items do
    from(i in Item, where: i.is_active == true)
    |> Repo.all()
  end

  def get_item!(id), do: Repo.get!(Item, id)

  def get_item(id), do: Repo.get(Item, id)

  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert()
  end

  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  def change_item(%Item{} = item, attrs \\ %{}) do
    Item.changeset(item, attrs)
  end

  ## Character Inventory

  def get_character_inventory(character_id) do
    from(ci in CharacterInventory,
      where: ci.character_id == ^character_id,
      preload: [:item],
      order_by: [asc: :slot_position]
    )
    |> Repo.all()
  end

  def get_character_equipped_items(character_id) do
    from(ci in CharacterInventory,
      where: ci.character_id == ^character_id and ci.equipped == true,
      preload: [:item]
    )
    |> Repo.all()
  end

  def add_item_to_inventory(character_id, item_id, quantity \\ 1, opts \\ []) do
    item = get_item!(item_id)

    if item.stackable do
      add_stackable_item(character_id, item, quantity, opts)
    else
      add_non_stackable_item(character_id, item, quantity, opts)
    end
  end

  defp add_stackable_item(character_id, item, quantity, opts) do
    case find_existing_stack(character_id, item.id) do
      nil ->
        create_inventory_entry(character_id, item, quantity, opts)

      existing ->
        new_quantity = existing.quantity + quantity

        if new_quantity <= item.max_stack_size do
          update_inventory_quantity(existing, new_quantity)
        else
          # Split into multiple stacks if needed
          remaining = new_quantity - item.max_stack_size

          with {:ok, _} <- update_inventory_quantity(existing, item.max_stack_size),
               {:ok, _} <- add_stackable_item(character_id, item, remaining, opts) do
            {:ok, :split_stack}
          end
        end
    end
  end

  defp add_non_stackable_item(character_id, item, quantity, opts) do
    Enum.reduce_while(1..quantity, {:ok, []}, fn _, {:ok, acc} ->
      case create_inventory_entry(character_id, item, 1, opts) do
        {:ok, entry} -> {:cont, {:ok, [entry | acc]}}
        error -> {:halt, error}
      end
    end)
  end

  defp find_existing_stack(character_id, item_id) do
    from(ci in CharacterInventory,
      where: ci.character_id == ^character_id and ci.item_id == ^item_id and ci.equipped == false,
      limit: 1
    )
    |> Repo.one()
  end

  defp create_inventory_entry(character_id, item, quantity, opts) do
    slot_position = Keyword.get(opts, :slot_position) || find_next_available_slot(character_id)

    %CharacterInventory{}
    |> CharacterInventory.changeset(%{
      character_id: character_id,
      item_id: item.id,
      quantity: quantity,
      slot_position: slot_position
    })
    |> Repo.insert()
  end

  defp update_inventory_quantity(inventory, new_quantity) do
    inventory
    |> CharacterInventory.changeset(%{quantity: new_quantity})
    |> Repo.update()
  end

  defp find_next_available_slot(character_id) do
    used_slots =
      from(ci in CharacterInventory,
        where: ci.character_id == ^character_id,
        select: ci.slot_position
      )
      |> Repo.all()
      |> MapSet.new()

    Enum.find(0..99, fn slot -> not MapSet.member?(used_slots, slot) end) || 0
  end

  def remove_item_from_inventory(inventory_id, quantity \\ 1) do
    inventory = Repo.get!(CharacterInventory, inventory_id)

    cond do
      inventory.quantity > quantity ->
        update_inventory_quantity(inventory, inventory.quantity - quantity)

      inventory.quantity == quantity ->
        Repo.delete(inventory)

      true ->
        {:error, :insufficient_quantity}
    end
  end

  def equip_item(inventory_id) do
    inventory = Repo.get!(CharacterInventory, inventory_id) |> Repo.preload(:item)

    if inventory.item.equippable do
      # Unequip any existing item in the same slot
      unequip_slot(inventory.character_id, inventory.item.equipment_slot)

      inventory
      |> CharacterInventory.changeset(%{
        equipped: true,
        equipment_slot: inventory.item.equipment_slot
      })
      |> Repo.update()
    else
      {:error, :not_equippable}
    end
  end

  def unequip_item(inventory_id) do
    inventory = Repo.get!(CharacterInventory, inventory_id)

    inventory
    |> CharacterInventory.changeset(%{equipped: false, equipment_slot: nil})
    |> Repo.update()
  end

  defp unequip_slot(character_id, equipment_slot) do
    from(ci in CharacterInventory,
      where: ci.character_id == ^character_id and ci.equipment_slot == ^equipment_slot
    )
    |> Repo.update_all(set: [equipped: false, equipment_slot: nil])
  end

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
    inventory = Repo.get!(CharacterInventory, inventory_id) |> Repo.preload(:item)

    if inventory.quantity >= quantity do
      Repo.transaction(fn ->
        # Create room item
        {:ok, room_item} =
          %RoomItem{}
          |> RoomItem.changeset(%{
            location: location,
            item_id: inventory.item_id,
            quantity: quantity,
            dropped_by_character_id: character_id
          })
          |> Repo.insert()

        # Remove from inventory
        case remove_item_from_inventory(inventory_id, quantity) do
          {:ok, _} -> room_item
          error -> Repo.rollback(error)
        end
      end)
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
      case add_item_to_inventory(character_id, room_item.item_id, pickup_quantity) do
        {:ok, _} ->
          handle_room_item_removal(room_item, pickup_quantity)

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

  ## Spell Scrolls

  @doc """
  Use a spell scroll to learn a spell.
  Consumes the scroll from inventory and teaches the spell to the character.
  """
  def use_spell_scroll(character_id, inventory_id) do
    inventory = Repo.get!(CharacterInventory, inventory_id) |> Repo.preload(:item)
    item = inventory.item

    cond do
      is_nil(item.spell_id) ->
        {:error, :not_a_spell_scroll}

      not item.usable ->
        {:error, :not_usable}

      true ->
        # Learn the spell
        spell = Shard.Spells.get_spell!(item.spell_id)

        already_known = Shard.Spells.character_knows_spell?(character_id, item.spell_id)

        result = if already_known do
          {:ok, :already_known, spell}
        else
          case Shard.Spells.add_spell_to_character(character_id, item.spell_id) do
            {:ok, _character_spell} ->
              {:ok, :learned, spell}
            {:error, changeset} ->
              {:error, changeset}
          end
        end

        # Remove scroll from inventory (consume it)
        case result do
          {:ok, status, spell} ->
            remove_item_from_inventory(inventory_id, 1)
            {:ok, status, spell}
          error ->
            error
        end
    end
  end

  @doc """
  Check if an item is a spell scroll.
  """
  def is_spell_scroll?(item) do
    not is_nil(item.spell_id) and item.usable
  end

  ## Hotbar

  def get_character_hotbar(character_id) do
    from(hs in HotbarSlot,
      where: hs.character_id == ^character_id,
      preload: [:item, :inventory],
      order_by: [asc: :slot_number]
    )
    |> Repo.all()
  end

  def set_hotbar_slot(character_id, slot_number, inventory_id \\ nil) do
    inventory = if inventory_id, do: Repo.get!(CharacterInventory, inventory_id), else: nil

    attrs = %{
      character_id: character_id,
      slot_number: slot_number,
      item_id: inventory && inventory.item_id,
      inventory_id: inventory_id
    }

    case Repo.get_by(HotbarSlot, character_id: character_id, slot_number: slot_number) do
      nil ->
        %HotbarSlot{}
        |> HotbarSlot.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> HotbarSlot.changeset(attrs)
        |> Repo.update()
    end
  end

  def clear_hotbar_slot(character_id, slot_number) do
    case Repo.get_by(HotbarSlot, character_id: character_id, slot_number: slot_number) do
      nil -> {:ok, nil}
      hotbar_slot -> Repo.delete(hotbar_slot)
    end
  end

  ## Tutorial Items

  def create_tutorial_key do
    alias Shard.Items.{Item, RoomItem}

    # Check if tutorial key already exists in the room at (0,2,0)
    existing_key =
      from(ri in RoomItem,
        where: ri.location == "0,2,0",
        join: i in Item,
        on: ri.item_id == i.id,
        where: i.name == "Tutorial Key"
      )
      |> Repo.one()

    if is_nil(existing_key) do
      Repo.transaction(fn ->
        # Create the tutorial key item if it doesn't exist in the items table
        {:ok, key_item} =
          case Repo.get_by(Item, name: "Tutorial Key") do
            nil ->
              %Item{}
              |> Item.changeset(%{
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

            existing_item ->
              {:ok, existing_item}
          end

        # Place the key in the room at (0,2,0)
        %RoomItem{}
        |> RoomItem.changeset(%{
          item_id: key_item.id,
          location: "0,2,0",
          quantity: 1
        })
        |> Repo.insert()
      end)
    else
      {:ok, existing_key}
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
end
