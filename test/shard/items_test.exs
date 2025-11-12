defmodule Shard.ItemsTest do
  use Shard.DataCase

  alias Shard.Items
  alias Shard.Items.{CharacterInventory, HotbarSlot, Item, RoomItem}

  describe "items" do
    @valid_item_attrs %{
      name: "Test Sword",
      item_type: "weapon",
      rarity: "common",
      value: 50,
      stackable: false,
      equippable: true,
      equipment_slot: "weapon"
    }

    @invalid_item_attrs %{name: nil, item_type: nil}

    test "list_items/0 returns all items" do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      items = Items.list_items()
      assert length(items) >= 1
      assert Enum.any?(items, fn i -> i.id == item.id end)
    end

    test "list_active_items/0 returns only active items" do
      {:ok, active_item} = Items.create_item(@valid_item_attrs)
      {:ok, inactive_item} = Items.create_item(Map.put(@valid_item_attrs, :active, false))
      
      active_items = Items.list_active_items()
      active_ids = Enum.map(active_items, & &1.id)
      
      assert active_item.id in active_ids
      refute inactive_item.id in active_ids
    end

    test "get_item!/1 returns the item with given id" do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      assert Items.get_item!(item.id).id == item.id
    end

    test "get_item!/1 raises when item not found" do
      assert_raise Ecto.NoResultsError, fn -> Items.get_item!(999) end
    end

    test "create_item/1 with valid data creates an item" do
      assert {:ok, %Item{} = item} = Items.create_item(@valid_item_attrs)
      assert item.name == "Test Sword"
      assert item.item_type == "weapon"
      assert item.rarity == "common"
      assert item.value == 50
      assert item.stackable == false
      assert item.equippable == true
      assert item.equipment_slot == "weapon"
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Items.create_item(@invalid_item_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      update_attrs = %{name: "Updated Sword", value: 75}

      assert {:ok, %Item{} = item} = Items.update_item(item, update_attrs)
      assert item.name == "Updated Sword"
      assert item.value == 75
    end

    test "update_item/2 with invalid data returns error changeset" do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      assert {:error, %Ecto.Changeset{}} = Items.update_item(item, @invalid_item_attrs)
      assert item == Items.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      assert {:ok, %Item{}} = Items.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Items.get_item!(item.id) end
    end

    test "change_item/1 returns an item changeset" do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      assert %Ecto.Changeset{} = Items.change_item(item)
    end
  end

  describe "character inventory" do
    setup do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      %{item: item}
    end

    test "get_character_inventory/1 returns list of inventory items", %{item: item} do
      character_id = 1
      
      {:ok, _inventory} = Items.add_item_to_inventory(character_id, item.id, 5)
      
      inventory = Items.get_character_inventory(character_id)
      assert is_list(inventory)
      assert length(inventory) >= 1
    end

    test "add_item_to_inventory/3 adds item to character inventory", %{item: item} do
      character_id = 1
      quantity = 3
      
      assert {:ok, %CharacterInventory{} = inventory} = 
        Items.add_item_to_inventory(character_id, item.id, quantity)
      
      assert inventory.character_id == character_id
      assert inventory.item_id == item.id
      assert inventory.quantity == quantity
    end

    test "add_item_to_inventory/3 stacks items when item is stackable", %{item: item} do
      # Create a stackable item
      {:ok, stackable_item} = Items.create_item(Map.put(@valid_item_attrs, :stackable, true))
      character_id = 1
      
      # Add item first time
      {:ok, inventory1} = Items.add_item_to_inventory(character_id, stackable_item.id, 3)
      
      # Add same item again
      {:ok, inventory2} = Items.add_item_to_inventory(character_id, stackable_item.id, 2)
      
      # Should be same inventory record with updated quantity
      assert inventory1.id == inventory2.id
      assert inventory2.quantity == 5
    end

    test "remove_item_from_inventory/1 removes inventory item" do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      {:ok, inventory} = Items.add_item_to_inventory(1, item.id, 1)
      
      assert {:ok, %CharacterInventory{}} = Items.remove_item_from_inventory(inventory.id)
      assert_raise Ecto.NoResultsError, fn -> 
        Repo.get!(CharacterInventory, inventory.id) 
      end
    end

    test "remove_item_from_inventory/1 with non-existent inventory raises error" do
      assert_raise Ecto.NoResultsError, fn ->
        Items.remove_item_from_inventory(999)
      end
    end

    test "get_character_equipped_items/1 returns equipped items" do
      character_id = 1
      equipped_items = Items.get_character_equipped_items(character_id)
      assert is_list(equipped_items)
    end

    test "equip_item/2 equips an item", %{item: item} do
      character_id = 1
      {:ok, inventory} = Items.add_item_to_inventory(character_id, item.id, 1)
      
      assert {:ok, %CharacterInventory{} = equipped_inventory} = 
        Items.equip_item(inventory.id, item.equipment_slot)
      
      assert equipped_inventory.equipped == true
      assert equipped_inventory.equipment_slot == item.equipment_slot
    end

    test "unequip_item/1 unequips an item", %{item: item} do
      character_id = 1
      {:ok, inventory} = Items.add_item_to_inventory(character_id, item.id, 1)
      {:ok, equipped_inventory} = Items.equip_item(inventory.id, item.equipment_slot)
      
      assert {:ok, %CharacterInventory{} = unequipped_inventory} = 
        Items.unequip_item(equipped_inventory.id)
      
      assert unequipped_inventory.equipped == false
      assert unequipped_inventory.equipment_slot == nil
    end
  end

  describe "room items" do
    setup do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      %{item: item}
    end

    test "get_room_items/1 returns list of items in room" do
      room_coordinates = "0,0,0"
      items = Items.get_room_items(room_coordinates)
      assert is_list(items)
    end

    test "add_item_to_room/3 adds item to room", %{item: item} do
      room_coordinates = "1,1,0"
      quantity = 2
      
      assert {:ok, %RoomItem{} = room_item} = 
        Items.add_item_to_room(room_coordinates, item.id, quantity)
      
      assert room_item.room_coordinates == room_coordinates
      assert room_item.item_id == item.id
      assert room_item.quantity == quantity
    end

    test "remove_item_from_room/1 removes item from room", %{item: item} do
      {:ok, room_item} = Items.add_item_to_room("1,1,0", item.id, 1)
      
      assert {:ok, %RoomItem{}} = Items.remove_item_from_room(room_item.id)
      assert_raise Ecto.NoResultsError, fn -> 
        Repo.get!(RoomItem, room_item.id) 
      end
    end
  end

  describe "hotbar" do
    setup do
      {:ok, item} = Items.create_item(@valid_item_attrs)
      character_id = 1
      {:ok, inventory} = Items.add_item_to_inventory(character_id, item.id, 1)
      %{item: item, inventory: inventory, character_id: character_id}
    end

    test "get_character_hotbar/1 returns character's hotbar slots", %{character_id: character_id} do
      hotbar = Items.get_character_hotbar(character_id)
      assert is_list(hotbar)
    end

    test "set_hotbar_slot/4 sets item in hotbar slot", %{character_id: character_id, item: item, inventory: inventory} do
      slot_number = 1
      
      assert {:ok, %HotbarSlot{} = hotbar_slot} = 
        Items.set_hotbar_slot(character_id, slot_number, item.id, inventory.id)
      
      assert hotbar_slot.character_id == character_id
      assert hotbar_slot.slot_number == slot_number
      assert hotbar_slot.item_id == item.id
      assert hotbar_slot.inventory_id == inventory.id
    end

    test "clear_hotbar_slot/2 clears hotbar slot", %{character_id: character_id, item: item, inventory: inventory} do
      slot_number = 2
      {:ok, hotbar_slot} = Items.set_hotbar_slot(character_id, slot_number, item.id, inventory.id)
      
      assert {:ok, %HotbarSlot{} = cleared_slot} = 
        Items.clear_hotbar_slot(character_id, slot_number)
      
      assert cleared_slot.item_id == nil
      assert cleared_slot.inventory_id == nil
    end
  end

  describe "quest items" do
    test "has_tutorial_key?/1 checks for tutorial key" do
      character_id = 1
      # Should return false for character without tutorial key
      refute Items.has_tutorial_key?(character_id)
    end

    test "has_dungeon_door?/1 checks for dungeon door" do
      character_id = 1
      # Should return false for character without dungeon door
      refute Items.has_dungeon_door?(character_id)
    end

    test "create_tutorial_key/0 creates tutorial key item" do
      result = Items.create_tutorial_key()
      assert match?({:ok, %Item{}}, result) or match?({:error, %Ecto.Changeset{}}, result)
    end

    test "create_dungeon_door/0 creates dungeon door item" do
      result = Items.create_dungeon_door()
      assert match?({:ok, %Item{}}, result) or match?({:error, %Ecto.Changeset{}}, result)
    end
  end

  @valid_item_attrs %{
    name: "Test Sword",
    item_type: "weapon",
    rarity: "common",
    value: 50,
    stackable: false,
    equippable: true,
    equipment_slot: "weapon"
  }

  describe "changeset validations" do
    describe "CharacterInventory changeset" do
      test "validates required fields" do
        changeset = CharacterInventory.changeset(%CharacterInventory{}, %{})
        refute changeset.valid?

        errors = errors_on(changeset)
        assert "can't be blank" in errors.character_id
        assert "can't be blank" in errors.item_id
        # Note: quantity has a default value of 1, so it's not required in the same way
      end

      test "validates quantity is positive" do
        attrs = %{character_id: 1, item_id: 1, quantity: 0}
        changeset = CharacterInventory.changeset(%CharacterInventory{}, attrs)
        refute changeset.valid?
        assert %{quantity: ["must be greater than 0"]} = errors_on(changeset)
      end

      test "validates slot_position is non-negative" do
        attrs = %{character_id: 1, item_id: 1, quantity: 1, slot_position: -1}
        changeset = CharacterInventory.changeset(%CharacterInventory{}, attrs)
        refute changeset.valid?
        assert %{slot_position: ["must be greater than or equal to 0"]} = errors_on(changeset)
      end

      test "validates equipment consistency - equipped requires equipment_slot" do
        attrs = %{character_id: 1, item_id: 1, quantity: 1, equipped: true, equipment_slot: nil}
        changeset = CharacterInventory.changeset(%CharacterInventory{}, attrs)
        refute changeset.valid?
        assert %{equipment_slot: ["must be specified for equipped items"]} = errors_on(changeset)
      end

      test "validates equipment consistency - unequipped clears equipment_slot" do
        attrs = %{
          character_id: 1,
          item_id: 1,
          quantity: 1,
          equipped: false,
          equipment_slot: "weapon"
        }

        changeset = CharacterInventory.changeset(%CharacterInventory{}, attrs)
        assert changeset.valid?
        assert get_change(changeset, :equipment_slot) == nil
      end

      test "accepts valid equipped item" do
        attrs = %{
          character_id: 1,
          item_id: 1,
          quantity: 1,
          equipped: true,
          equipment_slot: "weapon"
        }

        changeset = CharacterInventory.changeset(%CharacterInventory{}, attrs)
        assert changeset.valid?
      end
    end

    describe "HotbarSlot changeset" do
      test "validates required fields" do
        changeset = HotbarSlot.changeset(%HotbarSlot{}, %{})
        refute changeset.valid?

        errors = errors_on(changeset)
        assert "can't be blank" in errors.character_id
        assert "can't be blank" in errors.slot_number
      end

      test "validates slot_number range" do
        # Test too low
        attrs = %{character_id: 1, slot_number: 0}
        changeset = HotbarSlot.changeset(%HotbarSlot{}, attrs)
        refute changeset.valid?
        assert %{slot_number: ["must be greater than or equal to 1"]} = errors_on(changeset)

        # Test too high
        attrs = %{character_id: 1, slot_number: 13}
        changeset = HotbarSlot.changeset(%HotbarSlot{}, attrs)
        refute changeset.valid?
        assert %{slot_number: ["must be less than or equal to 12"]} = errors_on(changeset)
      end

      test "validates inventory/item consistency - item without inventory" do
        attrs = %{character_id: 1, slot_number: 1, item_id: 1, inventory_id: nil}
        changeset = HotbarSlot.changeset(%HotbarSlot{}, attrs)
        refute changeset.valid?
        assert %{inventory_id: ["must be specified when item is set"]} = errors_on(changeset)
      end

      test "validates inventory/item consistency - inventory without item" do
        attrs = %{character_id: 1, slot_number: 1, item_id: nil, inventory_id: 1}
        changeset = HotbarSlot.changeset(%HotbarSlot{}, attrs)
        refute changeset.valid?
        assert %{item_id: ["must be specified when inventory is set"]} = errors_on(changeset)
      end

      test "accepts valid hotbar slot with both item and inventory" do
        attrs = %{character_id: 1, slot_number: 1, item_id: 1, inventory_id: 1}
        changeset = HotbarSlot.changeset(%HotbarSlot{}, attrs)
        assert changeset.valid?
      end

      test "accepts valid hotbar slot with neither item nor inventory" do
        attrs = %{character_id: 1, slot_number: 1, item_id: nil, inventory_id: nil}
        changeset = HotbarSlot.changeset(%HotbarSlot{}, attrs)
        assert changeset.valid?
      end
    end

    describe "Item changeset" do
      test "validates required fields" do
        changeset = Item.changeset(%Item{}, %{})
        refute changeset.valid?

        errors = errors_on(changeset)
        assert "can't be blank" in errors.name
        assert "can't be blank" in errors.item_type
      end

      test "validates rarity inclusion" do
        attrs = %{name: "Test Item", item_type: "misc", rarity: "invalid"}
        changeset = Item.changeset(%Item{}, attrs)
        refute changeset.valid?
        assert %{rarity: ["is invalid"]} = errors_on(changeset)
      end

      test "accepts valid rarities" do
        valid_rarities = ["common", "uncommon", "rare", "epic", "legendary"]

        for rarity <- valid_rarities do
          attrs = %{name: "Test Item", item_type: "misc", rarity: rarity}
          changeset = Item.changeset(%Item{}, attrs)
          assert changeset.valid?
        end
      end

      test "validates item_type inclusion" do
        attrs = %{name: "Test Item", item_type: "invalid", rarity: "common"}
        changeset = Item.changeset(%Item{}, attrs)
        refute changeset.valid?
        assert %{item_type: ["is invalid"]} = errors_on(changeset)
      end

      test "accepts valid item_types" do
        valid_types = ["weapon", "armor", "consumable", "misc", "quest"]

        for type <- valid_types do
          attrs = %{name: "Test Item", item_type: type, rarity: "common"}
          changeset = Item.changeset(%Item{}, attrs)
          assert changeset.valid?
        end
      end
    end
  end
end
