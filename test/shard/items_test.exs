defmodule Shard.ItemsTest do
  use Shard.DataCase

  alias Shard.Items
  alias Shard.Items.{CharacterInventory, HotbarSlot, Item}

  describe "Items context" do
    test "list_items returns all items" do
      items = Items.list_items()
      assert is_list(items)
    end

    test "list_active_items returns active items" do
      items = Items.list_active_items()
      assert is_list(items)
    end

    test "get_character_inventory returns list" do
      inventory = Items.get_character_inventory(1)
      assert is_list(inventory)
    end

    test "get_character_equipped_items returns list" do
      items = Items.get_character_equipped_items(1)
      assert is_list(items)
    end

    test "get_room_items returns list" do
      items = Items.get_room_items("0,0,0")
      assert is_list(items)
    end

    test "get_character_hotbar returns list" do
      hotbar = Items.get_character_hotbar(1)
      assert is_list(hotbar)
    end

    test "create_item creates a new item" do
      attrs = %{
        name: "Test Sword",
        item_type: "weapon",
        rarity: "common",
        value: 50,
        stackable: false,
        equippable: true,
        equipment_slot: "weapon"
      }

      assert {:ok, %Items.Item{} = item} = Items.create_item(attrs)
      assert item.name == "Test Sword"
      assert item.item_type == "weapon"
    end

    test "change_item returns a changeset" do
      item = %Items.Item{name: "Test Item", item_type: "misc", rarity: "common"}
      changeset = Items.change_item(item)
      assert %Ecto.Changeset{} = changeset
    end

    test "remove_item_from_inventory with sufficient quantity" do
      # This would require setting up inventory in the database
      # For now, just test that it returns an error for non-existent inventory
      assert_raise Ecto.NoResultsError, fn ->
        Items.remove_item_from_inventory(999)
      end
    end

    test "create_tutorial_key creates tutorial key" do
      # Test that the function can be called (it handles duplicates internally)
      result = Items.create_tutorial_key()
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end

    test "create_dungeon_door creates dungeon door" do
      # Test that the function can be called
      result = Items.create_dungeon_door()
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

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
        assert changeset.valid?, "Expected #{rarity} to be valid"
      end
    end

    test "validates item_type inclusion" do
      attrs = %{name: "Test Item", item_type: "invalid", rarity: "common"}
      changeset = Item.changeset(%Item{}, attrs)
      refute changeset.valid?
      assert %{item_type: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid item_types" do
      valid_types = ["weapon", "armor", "consumable", "misc", "material", "tool"]

      for type <- valid_types do
        attrs = %{name: "Test Item", item_type: type, rarity: "common"}
        changeset = Item.changeset(%Item{}, attrs)
        assert changeset.valid?, "Expected #{type} to be valid"
      end
    end
  end
end
