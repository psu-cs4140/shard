# credo:disable-for-this-file Credo.Check.Refactor.Nesting
defmodule Shard.Items do
  @moduledoc """
  The Items context - Core items and inventory management.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Items.{Item, CharacterInventory, CharacterEquipment}

  ## Items

  def list_items do
    Item
    |> Repo.all()
    |> Repo.preload(:spell)
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
      join: i in Item,
      on: ci.item_id == i.id,
      where: ci.character_id == ^character_id and i.sellable == true,
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

  @doc """
  Add an item to a character's inventory. Alias for add_item_to_inventory for consistency.
  """
  def add_item_to_character(character_id, item_id, quantity \\ 1, opts \\ []) do
    add_item_to_inventory(character_id, item_id, quantity, opts)
  end

  defp add_stackable_item(_character_id, _item, quantity, _opts) when quantity <= 0 do
    {:ok, :noop}
  end

  defp add_stackable_item(character_id, item, quantity, opts) do
    max_stack_size = item.max_stack_size || 99

    case find_existing_stack(character_id, item.id, max_stack_size) do
      %CharacterInventory{} = stack ->
        available_space = max_stack_size - (stack.quantity || 0)
        to_add = min(quantity, available_space)
        new_quantity = (stack.quantity || 0) + to_add

        with {:ok, updated_stack} <- update_inventory_quantity(stack, new_quantity) do
          handle_remaining_stackable(character_id, item, quantity - to_add, opts, updated_stack)
        end

      nil ->
        to_add = min(quantity, max_stack_size)

        with {:ok, new_stack} <- create_inventory_entry(character_id, item, to_add, opts) do
          handle_remaining_stackable(character_id, item, quantity - to_add, opts, new_stack)
        end
    end
  end

  defp add_non_stackable_item(character_id, item, quantity, opts) do
    result =
      Enum.reduce_while(1..quantity, {:ok, []}, fn _, {:ok, acc} ->
        case create_inventory_entry(character_id, item, 1, opts) do
          {:ok, entry} -> {:cont, {:ok, [entry | acc]}}
          error -> {:halt, error}
        end
      end)

    case result do
      {:ok, entries} -> {:ok, entries}
      error -> error
    end
  end

  defp find_existing_stack(character_id, item_id, max_stack_size) do
    from(ci in CharacterInventory,
      where:
        ci.character_id == ^character_id and ci.item_id == ^item_id and ci.equipped == false and
          ci.quantity < ^max_stack_size,
      limit: 1
    )
    |> Repo.one()
  end

  defp handle_remaining_stackable(_character_id, _item, remaining, _opts, result)
       when remaining <= 0 do
    {:ok, result}
  end

  defp handle_remaining_stackable(character_id, item, remaining, opts, _result) do
    add_stackable_item(character_id, item, remaining, opts)
  end

  defp create_inventory_entry(character_id, item, quantity, opts) do
    slot_position = Keyword.get(opts, :slot_position) || find_next_available_slot(character_id)

    changeset_attrs = %{
      character_id: character_id,
      item_id: item.id,
      quantity: quantity,
      slot_position: slot_position
    }

    result =
      %CharacterInventory{}
      |> CharacterInventory.changeset(changeset_attrs)
      |> Repo.insert()

    case result do
      {:ok, inventory} ->
        {:ok, inventory}

      {:error, changeset} ->
        {:error, changeset}
    end
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

  @doc """
  Sells an item from a character's inventory.

  Removes the item (or reduces quantity by 1) and adds gold to the character.
  Uses the item's value field, defaulting to 1 if not set.

  Returns {:ok, %{character: character, gold_earned: amount}} on success.

  ## Examples

      iex> sell_item(character, inventory_id)
      {:ok, %{character: %Character{gold: 150}, gold_earned: 50}}

      iex> sell_item(character, invalid_id)
      {:error, :item_not_found}
  """
  def sell_item(character, inventory_id, quantity \\ 1) do
    alias Ecto.Multi
    # alias Shard.Characters
    alias Shard.Characters.Character
    quantity_int = max(1, quantity)

    inventory_item =
      Repo.get(CharacterInventory, inventory_id)
      |> Repo.preload(:item)

    case inventory_item do
      nil ->
        {:error, :item_not_found}

      %{character_id: char_id} when char_id != character.id ->
        {:error, :not_owned_by_character}

      %{equipped: true} ->
        {:error, :cannot_sell_equipped_item}

      %{item: %{sellable: false}} ->
        {:error, :item_not_sellable}

      inventory_item ->
        if quantity_int > inventory_item.quantity do
          {:error, :invalid_quantity}
        else
          # Get the sell value from the item, default to 1 if not set
          sell_value = inventory_item.item.value || 1
          total_value = sell_value * quantity_int

          Multi.new()
          |> Multi.run(:remove_item, fn _repo, _changes ->
            remaining = inventory_item.quantity - quantity_int

            cond do
              remaining > 0 ->
                update_inventory_quantity(inventory_item, remaining)

              remaining == 0 ->
                Repo.delete(inventory_item)

              true ->
                {:error, :invalid_quantity}
            end
          end)
          |> Multi.run(:update_character, fn _repo, _changes ->
            character
            |> Character.changeset(%{gold: character.gold + total_value})
            |> Repo.update()
          end)
          |> Repo.transaction()
          |> case do
            {:ok, %{update_character: updated_character}} ->
              {:ok, %{character: updated_character, gold_earned: total_value}}

            {:error, _failed_operation, failed_value, _changes_so_far} ->
              {:error, failed_value}
          end
        end
    end
  end

  def equip_item(inventory_id) do
    inventory = Repo.get!(CharacterInventory, inventory_id) |> Repo.preload(:item)

    cond do
      not inventory.item.equippable ->
        {:error, :not_equippable}

      inventory.equipped ->
        {:error, :already_equipped}

      true ->
        # Unequip any existing item in the same slot
        unequip_slot(inventory.character_id, inventory.item.equipment_slot)

        inventory
        |> CharacterInventory.changeset(%{
          equipped: true,
          equipment_slot: inventory.item.equipment_slot
        })
        |> Repo.update()
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

  @doc """
  Checks if a character has a specific item in their inventory.

  ## Examples

      iex> character_has_item?(character_id, "Tutorial Key")
      true

      iex> character_has_item?(character_id, "Nonexistent Item")
      false

  """
  def character_has_item?(character_id, item_name) do
    from(ci in CharacterInventory,
      join: i in Item,
      on: ci.item_id == i.id,
      where: ci.character_id == ^character_id and ilike(i.name, ^item_name) and ci.quantity > 0
    )
    |> Repo.exists?()
  end

  @doc """
  Gets the quantity of a specific item in a character's inventory.

  ## Examples

      iex> get_character_item_quantity(character_id, "Tutorial Key")
      1

      iex> get_character_item_quantity(character_id, "Nonexistent Item")
      0

  """
  def get_character_item_quantity(character_id, item_name) do
    result =
      from(ci in CharacterInventory,
        join: i in Item,
        on: ci.item_id == i.id,
        where: ci.character_id == ^character_id and ilike(i.name, ^item_name),
        select: sum(ci.quantity)
      )
      |> Repo.one()

    result || 0
  end

  @doc """
  Checks if a specific item is currently equipped by a character.
  """
  def item_equipped?(character_id, item_id) do
    case Repo.get_by(CharacterEquipment, character_id: character_id, item_id: item_id) do
      nil -> false
      _equipment -> true
    end
  end

  @doc """
  Checks if a specific inventory item is currently equipped by a character (legacy system).
  """
  def inventory_item_equipped?(inventory_id) do
    case Repo.get(CharacterInventory, inventory_id) do
      nil -> false
      inventory -> inventory.equipped || false
    end
  end

  ## Character Equipment

  @doc """
  Gets all equipped items for a character.
  Returns a map with equipment slots as keys and items as values.
  """
  def get_equipped_items(character_id) do
    # Use the legacy CharacterInventory system that's actually being used by the game
    equipped_items =
      Repo.all(
        from ci in CharacterInventory,
          where: ci.character_id == ^character_id and ci.equipped == true,
          preload: [:item]
      )

    Enum.reduce(equipped_items, %{}, fn inv_item, acc ->
      slot = inv_item.equipment_slot || "unknown"
      Map.put(acc, slot, inv_item.item)
    end)
  end

  @doc """
  Equips an item to a character's equipment slot.
  """
  def equip_item_to_slot(character_id, item_id) do
    with {:ok, item} <- get_item_if_equippable(item_id),
         {:ok, _} <- check_if_item_already_equipped(character_id, item_id),
         {:ok, _} <- unequip_slot_if_occupied(character_id, item.equipment_slot),
         {:ok, equipment} <- create_equipment(character_id, item_id, item.equipment_slot) do
      {:ok, equipment}
    else
      error -> error
    end
  end

  @doc """
  Unequips an item from a character's equipment slot.
  """
  def unequip_item_from_slot(character_id, equipment_slot) do
    case get_equipment_by_slot(character_id, equipment_slot) do
      nil -> {:error, :not_equipped}
      equipment -> Repo.delete(equipment)
    end
  end

  defp get_item_if_equippable(item_id) do
    case Repo.get(Item, item_id) do
      nil ->
        {:error, :item_not_found}

      item ->
        if item.equippable do
          {:ok, item}
        else
          {:error, :item_not_equippable}
        end
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

        result =
          if already_known do
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
  def spell_scroll?(item) do
    not is_nil(item.spell_id) and item.usable
  end

  ## Loot Boxes

  @doc """
  Opens a loot box and gives random rewards to the character.
  Consumes the loot box from inventory.
  """
  def open_loot_box(character_id, inventory_id) do
    inventory = Repo.get!(CharacterInventory, inventory_id) |> Repo.preload(:item)
    item = inventory.item

    cond do
      item.item_type != "loot_box" ->
        {:error, :not_a_loot_box}

      not item.usable ->
        {:error, :not_usable}

      true ->
        # Generate random rewards based on loot box rarity
        rewards = generate_loot_box_rewards(item.rarity)
        
        # Give rewards to character
        case give_loot_box_rewards(character_id, rewards) do
          {:ok, given_rewards} ->
            # Remove loot box from inventory (consume it)
            remove_item_from_inventory(inventory_id, 1)
            {:ok, given_rewards}

          error ->
            error
        end
    end
  end

  @doc """
  Check if an item is a loot box.
  """
  def loot_box?(item) do
    item.item_type == "loot_box" and item.usable
  end

  @doc """
  Creates a loot box item with the specified rarity.
  """
  def create_loot_box(rarity \\ "common") do
    rarity_name = String.capitalize(rarity)
    
    create_item(%{
      name: "#{rarity_name} Loot Box",
      description: "A mysterious box containing random rewards. Rarity affects the quality of contents.",
      item_type: "loot_box",
      rarity: rarity,
      value: get_loot_box_price(rarity),
      weight: 1.0,
      stackable: true,
      max_stack_size: 10,
      usable: true,
      equippable: false,
      sellable: true,
      data: %{
        loot_table: get_loot_table_for_rarity(rarity)
      }
    })
  end

  defp generate_loot_box_rewards(rarity) do
    base_rewards = %{
      gold: get_gold_reward(rarity),
      experience: get_experience_reward(rarity),
      items: get_item_rewards(rarity)
    }

    # Add chance for bonus rewards based on rarity
    bonus_chance = get_bonus_chance(rarity)
    
    if :rand.uniform() < bonus_chance do
      Map.put(base_rewards, :bonus_gold, get_bonus_gold(rarity))
    else
      base_rewards
    end
  end

  defp give_loot_box_rewards(character_id, rewards) do
    alias Ecto.Multi
    alias Shard.Characters

    Multi.new()
    |> Multi.run(:update_character, fn _repo, _changes ->
      character = Characters.get_character!(character_id)
      gold_gain = Map.get(rewards, :gold, 0) + Map.get(rewards, :bonus_gold, 0)
      exp_gain = Map.get(rewards, :experience, 0)
      
      Characters.update_character(character, %{
        gold: character.gold + gold_gain,
        experience: character.experience + exp_gain
      })
    end)
    |> Multi.run(:give_items, fn _repo, _changes ->
      items = Map.get(rewards, :items, [])
      
      results = Enum.map(items, fn {item_id, quantity} ->
        add_item_to_inventory(character_id, item_id, quantity)
      end)
      
      # Check if all items were added successfully
      if Enum.all?(results, fn {status, _} -> status == :ok end) do
        {:ok, results}
      else
        {:error, :failed_to_give_items}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, _} -> {:ok, rewards}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end

  def get_loot_box_price("common"), do: 100
  def get_loot_box_price("uncommon"), do: 250
  def get_loot_box_price("rare"), do: 500
  def get_loot_box_price("epic"), do: 1000
  def get_loot_box_price("legendary"), do: 2500

  defp get_gold_reward("common"), do: Enum.random(10..50)
  defp get_gold_reward("uncommon"), do: Enum.random(25..100)
  defp get_gold_reward("rare"), do: Enum.random(50..200)
  defp get_gold_reward("epic"), do: Enum.random(100..500)
  defp get_gold_reward("legendary"), do: Enum.random(250..1000)

  defp get_experience_reward("common"), do: Enum.random(50..150)
  defp get_experience_reward("uncommon"), do: Enum.random(100..300)
  defp get_experience_reward("rare"), do: Enum.random(200..600)
  defp get_experience_reward("epic"), do: Enum.random(400..1200)
  defp get_experience_reward("legendary"), do: Enum.random(800..2500)

  defp get_item_rewards("common") do
    # 70% chance for 1 common item, 30% chance for nothing extra
    if :rand.uniform() < 0.7 do
      [{get_random_item_by_rarity("common"), 1}]
    else
      []
    end
  end

  defp get_item_rewards("uncommon") do
    # 80% chance for 1 item, 20% chance for 2 items
    count = if :rand.uniform() < 0.8, do: 1, else: 2
    
    Enum.map(1..count, fn _ ->
      rarity = if :rand.uniform() < 0.7, do: "common", else: "uncommon"
      {get_random_item_by_rarity(rarity), 1}
    end)
  end

  defp get_item_rewards("rare") do
    # Always 1-2 items, better rarity distribution
    count = Enum.random(1..2)
    
    Enum.map(1..count, fn _ ->
      rarity = case :rand.uniform() do
        x when x < 0.4 -> "common"
        x when x < 0.7 -> "uncommon"
        _ -> "rare"
      end
      {get_random_item_by_rarity(rarity), 1}
    end)
  end

  defp get_item_rewards("epic") do
    # Always 2-3 items, high rarity distribution
    count = Enum.random(2..3)
    
    Enum.map(1..count, fn _ ->
      rarity = case :rand.uniform() do
        x when x < 0.2 -> "common"
        x when x < 0.4 -> "uncommon"
        x when x < 0.7 -> "rare"
        _ -> "epic"
      end
      {get_random_item_by_rarity(rarity), 1}
    end)
  end

  defp get_item_rewards("legendary") do
    # Always 3-5 items, guaranteed high rarity
    count = Enum.random(3..5)
    
    Enum.map(1..count, fn _ ->
      rarity = case :rand.uniform() do
        x when x < 0.1 -> "uncommon"
        x when x < 0.3 -> "rare"
        x when x < 0.6 -> "epic"
        _ -> "legendary"
      end
      {get_random_item_by_rarity(rarity), 1}
    end)
  end

  def get_bonus_chance("common"), do: 0.1
  def get_bonus_chance("uncommon"), do: 0.2
  def get_bonus_chance("rare"), do: 0.3
  def get_bonus_chance("epic"), do: 0.5
  def get_bonus_chance("legendary"), do: 0.8

  defp get_bonus_gold("common"), do: Enum.random(5..25)
  defp get_bonus_gold("uncommon"), do: Enum.random(15..75)
  defp get_bonus_gold("rare"), do: Enum.random(30..150)
  defp get_bonus_gold("epic"), do: Enum.random(75..375)
  defp get_bonus_gold("legendary"), do: Enum.random(150..750)

  defp get_random_item_by_rarity(rarity) do
    # Get a random item of the specified rarity
    item = from(i in Item,
      where: i.rarity == ^rarity and i.is_active == true and i.item_type != "loot_box",
      order_by: fragment("RANDOM()"),
      limit: 1
    )
    |> Repo.one()

    case item do
      nil -> 
        # Fallback: create a basic item if none exist
        {:ok, fallback_item} = create_fallback_item(rarity)
        fallback_item.id
      item -> 
        item.id
    end
  end

  defp create_fallback_item(rarity) do
    create_item(%{
      name: "#{String.capitalize(rarity)} Gem",
      description: "A valuable gem that can be sold for gold.",
      item_type: "misc",
      rarity: rarity,
      value: get_loot_box_price(rarity) / 4,
      weight: 0.1,
      stackable: true,
      max_stack_size: 99,
      sellable: true
    })
  end

  defp get_loot_table_for_rarity(rarity) do
    %{
      gold_range: get_gold_range(rarity),
      exp_range: get_exp_range(rarity),
      item_count_range: get_item_count_range(rarity),
      bonus_chance: get_bonus_chance(rarity)
    }
  end

  def get_gold_range("common"), do: [10, 50]
  def get_gold_range("uncommon"), do: [25, 100]
  def get_gold_range("rare"), do: [50, 200]
  def get_gold_range("epic"), do: [100, 500]
  def get_gold_range("legendary"), do: [250, 1000]

  def get_exp_range("common"), do: [50, 150]
  def get_exp_range("uncommon"), do: [100, 300]
  def get_exp_range("rare"), do: [200, 600]
  def get_exp_range("epic"), do: [400, 1200]
  def get_exp_range("legendary"), do: [800, 2500]

  def get_item_count_range("common"), do: [0, 1]
  def get_item_count_range("uncommon"), do: [1, 2]
  def get_item_count_range("rare"), do: [1, 2]
  def get_item_count_range("epic"), do: [2, 3]
  def get_item_count_range("legendary"), do: [3, 5]

  defp unequip_slot_if_occupied(character_id, equipment_slot) do
    case get_equipment_by_slot(character_id, equipment_slot) do
      nil -> {:ok, nil}
      equipment -> Repo.delete(equipment)
    end
  end

  defp create_equipment(character_id, item_id, equipment_slot) do
    %CharacterEquipment{}
    |> CharacterEquipment.changeset(%{
      character_id: character_id,
      item_id: item_id,
      equipment_slot: equipment_slot
    })
    |> Repo.insert()
  end

  defp get_equipment_by_slot(character_id, equipment_slot) do
    Repo.get_by(CharacterEquipment, character_id: character_id, equipment_slot: equipment_slot)
  end

  defp check_if_item_already_equipped(character_id, item_id) do
    case Repo.get_by(CharacterEquipment, character_id: character_id, item_id: item_id) do
      nil -> {:ok, nil}
      _equipment -> {:error, :already_equipped}
    end
  end

  ## Delegation functions for backward compatibility

  @doc """
  Delegates to Shard.Items.GameFeatures.get_character_hotbar/1
  """
  def get_character_hotbar(character_id) do
    Shard.Items.GameFeatures.get_character_hotbar(character_id)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.pick_up_item/2
  """
  def pick_up_item(character_id, room_item_id, quantity \\ nil) do
    Shard.Items.GameFeatures.pick_up_item(character_id, room_item_id, quantity)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.get_room_items/1
  """
  def get_room_items(location) do
    Shard.Items.GameFeatures.get_room_items(location)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.drop_item_in_room/4
  """
  def drop_item_in_room(character_id, inventory_id, location, quantity \\ 1) do
    Shard.Items.GameFeatures.drop_item_in_room(character_id, inventory_id, location, quantity)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.set_hotbar_slot/3
  """
  def set_hotbar_slot(character_id, slot_number, inventory_id \\ nil) do
    Shard.Items.GameFeatures.set_hotbar_slot(character_id, slot_number, inventory_id)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.clear_hotbar_slot/2
  """
  def clear_hotbar_slot(character_id, slot_number) do
    Shard.Items.GameFeatures.clear_hotbar_slot(character_id, slot_number)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.has_tutorial_key?/1
  """
  def has_tutorial_key?(character_id) do
    Shard.Items.GameFeatures.has_tutorial_key?(character_id)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.has_dungeon_door?/1
  """
  def has_dungeon_door?(character_id) do
    Shard.Items.GameFeatures.has_dungeon_door?(character_id)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.create_tutorial_key/0
  """
  def create_tutorial_key do
    Shard.Items.GameFeatures.create_tutorial_key()
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.create_dungeon_door/0
  """
  def create_dungeon_door do
    Shard.Items.GameFeatures.create_dungeon_door()
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.character_has_quest_items?/2
  """
  def character_has_quest_items?(character_id, objectives) do
    Shard.Items.GameFeatures.character_has_quest_items?(character_id, objectives)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.create_room_item/1
  """
  def create_room_item(attrs) do
    Shard.Items.GameFeatures.create_room_item(attrs)
  end

  @doc """
  Delegates to Shard.Items.GameFeatures.list_room_items_by_zone/1
  """
  def list_room_items_by_zone(zone_id) do
    Shard.Items.GameFeatures.list_room_items_by_zone(zone_id)
  end

  ## Loot Box System Delegation

  @doc """
  Delegates to Shard.Items.LootBoxSystem.create_standard_loot_boxes/0
  """
  def create_standard_loot_boxes do
    Shard.Items.LootBoxSystem.create_standard_loot_boxes()
  end

  @doc """
  Delegates to Shard.Items.LootBoxSystem.get_marketplace_loot_boxes/0
  """
  def get_marketplace_loot_boxes do
    Shard.Items.LootBoxSystem.get_marketplace_loot_boxes()
  end

  @doc """
  Delegates to Shard.Items.LootBoxSystem.purchase_loot_box/2
  """
  def purchase_loot_box(character_id, loot_box_id) do
    Shard.Items.LootBoxSystem.purchase_loot_box(character_id, loot_box_id)
  end

  @doc """
  Delegates to Shard.Items.LootBoxSystem.get_loot_box_stats/1
  """
  def get_loot_box_stats(rarity) do
    Shard.Items.LootBoxSystem.get_loot_box_stats(rarity)
  end

  @doc """
  Delegates to Shard.Items.LootBoxSystem.preview_loot_box_rewards/1
  """
  def preview_loot_box_rewards(rarity) do
    Shard.Items.LootBoxSystem.preview_loot_box_rewards(rarity)
  end
end
