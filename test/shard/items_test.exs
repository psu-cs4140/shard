defmodule Shard.ItemsTest do
  use Shard.DataCase

  alias Shard.Items
  alias Shard.Items.{Item, CharacterInventory, RoomItem, HotbarSlot}
  alias Shard.Characters
  alias Shard.Characters.Character
  alias Shard.Repo

  describe "items" do
    alias Shard.Items.Item

    @valid_attrs %{
      name: "Test Item",
      description: "A test item",
      item_type: "misc",
      rarity: "common",
      value: 10,
      weight: Decimal.new("1.5"),
      stackable: true,
      max_stack_size: 10,
      usable: false,
      equippable: false,
      is_active: true,
      pickup: true
    }
    @update_attrs %{
      name: "Updated Test Item",
      description: "An updated test item",
      value: 20
    }
    @invalid_attrs %{
      name: nil,
      item_type: nil
    }

    def item_fixture(attrs \\ %{}) do
      {:ok, item} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Items.create_item()

      item
    end

    test "list_items/0 returns all items" do
      item = item_fixture()
      assert Items.list_items() == [item]
    end

    test "list_active_items/0 returns only active items" do
      active_item = item_fixture()
      inactive_item = item_fixture(%{name: "Inactive Item", is_active: false})
      assert Items.list_active_items() == [active_item]
    end

    test "get_item!/1 returns the item with given id" do
      item = item_fixture()
      assert Items.get_item!(item.id) == item
    end

    test "get_item/1 returns the item with given id" do
      item = item_fixture()
      assert Items.get_item(item.id) == item
    end

    test "get_item/1 returns nil for non-existent id" do
      assert Items.get_item(-1) == nil
    end

    test "create_item/1 with valid data creates an item" do
      assert {:ok, %Item{} = item} = Items.create_item(@valid_attrs)
      assert item.name == "Test Item"
      assert item.description == "A test item"
      assert item.item_type == "misc"
      assert item.rarity == "common"
      assert item.value == 10
    end

    test "create_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Items.create_item(@invalid_attrs)
    end

    test "update_item/2 with valid data updates the item" do
      item = item_fixture()
      assert {:ok, %Item{} = item} = Items.update_item(item, @update_attrs)
      assert item.name == "Updated Test Item"
      assert item.description == "An updated test item"
      assert item.value == 20
    end

    test "update_item/2 with invalid data returns error changeset" do
      item = item_fixture()
      assert {:error, %Ecto.Changeset{}} = Items.update_item(item, @invalid_attrs)
      assert item == Items.get_item!(item.id)
    end

    test "delete_item/1 deletes the item" do
      item = item_fixture()
      assert {:ok, %Item{}} = Items.delete_item(item)
      assert_raise Ecto.NoResultsError, fn -> Items.get_item!(item.id) end
    end

    test "change_item/1 returns a item changeset" do
      item = item_fixture()
      assert %Ecto.Changeset{} = Items.change_item(item)
    end
  end

  describe "character inventory" do
    alias Shard.Items.CharacterInventory

    def character_fixture(attrs \\ %{}) do
      {:ok, character} =
        attrs
        |> Enum.into(%{name: "Test Character", level: 1, experience: 0})
        |> Characters.create_character()

      character
    end

    def character_inventory_fixture(attrs \\ %{}) do
      character = character_fixture()
      item = item_fixture()

      {:ok, character_inventory} =
        attrs
        |> Enum.into(%{
          character_id: character.id,
          item_id: item.id,
          quantity: 1,
          slot_position: 0
        })
        |> Items.add_item_to_inventory(character.id, item.id)

      character_inventory
    end

    test "get_character_inventory/1 returns all inventory items for a character" do
      character = character_fixture()
      item = item_fixture()

      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, item.id, 5)

      inventory = Items.get_character_inventory(character.id)
      assert length(inventory) == 1
      assert List.first(inventory).id == inventory_item.id
    end

    test "get_character_equipped_items/1 returns only equipped items" do
      character = character_fixture()
      item = item_fixture(%{@valid_attrs | equippable: true, equipment_slot: "weapon"})

      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, item.id)
      {:ok, _} = Items.equip_item(inventory_item.id)

      equipped_items = Items.get_character_equipped_items(character.id)
      assert length(equipped_items) == 1
      assert List.first(equipped_items).id == inventory_item.id
      assert List.first(equipped_items).equipped == true
    end

    test "add_item_to_inventory/3 adds an item to character inventory" do
      character = character_fixture()
      item = item_fixture()

      assert {:ok, %CharacterInventory{} = inventory} =
               Items.add_item_to_inventory(character.id, item.id, 3)

      assert inventory.character_id == character.id
      assert inventory.item_id == item.id
      assert inventory.quantity == 3
    end

    test "add_item_to_inventory/3 handles stackable items correctly" do
      character = character_fixture()
      stackable_item = item_fixture(%{@valid_attrs | stackable: true, max_stack_size: 5})

      {:ok, first_stack} = Items.add_item_to_inventory(character.id, stackable_item.id, 3)
      {:ok, _} = Items.add_item_to_inventory(character.id, stackable_item.id, 2)

      # Should combine into one stack
      inventory = Items.get_character_inventory(character.id)
      assert length(inventory) == 1
      assert List.first(inventory).quantity == 5
    end

    test "remove_item_from_inventory/2 removes quantity from inventory" do
      character = character_fixture()
      item = item_fixture()

      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, item.id, 5)
      assert {:ok, %CharacterInventory{}} = Items.remove_item_from_inventory(inventory_item.id, 2)

      updated_item = Repo.get(CharacterInventory, inventory_item.id)
      assert updated_item.quantity == 3
    end

    test "remove_item_from_inventory/2 deletes item when quantity reaches zero" do
      character = character_fixture()
      item = item_fixture()

      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, item.id, 1)
      assert {:ok, %CharacterInventory{}} = Items.remove_item_from_inventory(inventory_item.id, 1)

      assert Repo.get(CharacterInventory, inventory_item.id) == nil
    end

    test "equip_item/1 equips an item" do
      character = character_fixture()
      equippable_item = item_fixture(%{@valid_attrs | equippable: true, equipment_slot: "weapon"})

      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, equippable_item.id)
      assert {:ok, %CharacterInventory{} = equipped_item} = Items.equip_item(inventory_item.id)

      assert equipped_item.equipped == true
      assert equipped_item.equipment_slot == "weapon"
    end

    test "unequip_item/1 unequips an item" do
      character = character_fixture()
      equippable_item = item_fixture(%{@valid_attrs | equippable: true, equipment_slot: "weapon"})

      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, equippable_item.id)
      {:ok, _} = Items.equip_item(inventory_item.id)

      assert {:ok, %CharacterInventory{} = unequipped_item} =
               Items.unequip_item(inventory_item.id)

      assert unequipped_item.equipped == false
      assert unequipped_item.equipment_slot == nil
    end
  end

  describe "room items" do
    alias Shard.Items.RoomItem

    def room_item_fixture(attrs \\ %{}) do
      item = item_fixture()
      character = character_fixture()

      {:ok, room_item} =
        attrs
        |> Enum.into(%{
          location: "0,0,0",
          item_id: item.id,
          quantity: 1,
          dropped_by_character_id: character.id
        })
        |> Items.create_room_item()

      room_item
    end

    def create_room_item(attrs \\ %{}) do
      item = item_fixture()
      character = character_fixture()

      {:ok, room_item} =
        attrs
        |> Enum.into(%{
          location: "0,0,0",
          item_id: item.id,
          quantity: 1,
          dropped_by_character_id: character.id
        })
        |> Repo.insert()

      room_item
    end

    test "get_room_items/1 returns all items in a location" do
      location = "1,2,3"
      room_item = create_room_item(%{location: location})

      items = Items.get_room_items(location)
      assert length(items) == 1
      assert List.first(items).id == room_item.id
    end

    test "drop_item_in_room/4 moves item from inventory to room" do
      character = character_fixture()
      item = item_fixture()

      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, item.id, 3)

      assert {:ok, %RoomItem{}} =
               Items.drop_item_in_room(character.id, inventory_item.id, "5,5,0", 2)

      # Check that room item was created
      room_items = Items.get_room_items("5,5,0")
      assert length(room_items) == 1
      assert List.first(room_items).quantity == 2

      # Check that inventory was updated
      updated_inventory = Repo.get(CharacterInventory, inventory_item.id)
      assert updated_inventory.quantity == 1
    end

    test "pick_up_item/3 moves item from room to inventory" do
      character = character_fixture()
      room_item = create_room_item(%{quantity: 5})

      assert {:ok, :picked_up} = Items.pick_up_item(character.id, room_item.id, 3)

      # Check that room item was updated
      updated_room_item = Repo.get(RoomItem, room_item.id)
      assert updated_room_item.quantity == 2

      # Check that inventory was created
      inventory = Items.get_character_inventory(character.id)
      assert length(inventory) == 1
      assert List.first(inventory).quantity == 3
    end

    test "pick_up_item/3 removes room item when picking up all quantity" do
      character = character_fixture()
      room_item = create_room_item(%{quantity: 1})

      assert {:ok, :picked_up} = Items.pick_up_item(character.id, room_item.id, 1)

      # Check that room item was deleted
      assert Repo.get(RoomItem, room_item.id) == nil

      # Check that inventory was created
      inventory = Items.get_character_inventory(character.id)
      assert length(inventory) == 1
    end
  end

  describe "hotbar" do
    alias Shard.Items.HotbarSlot

    def hotbar_slot_fixture(attrs \\ %{}) do
      character = character_fixture()
      item = item_fixture()
      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, item.id)

      {:ok, hotbar_slot} =
        attrs
        |> Enum.into(%{
          character_id: character.id,
          slot_number: 1,
          item_id: item.id,
          inventory_id: inventory_item.id
        })
        |> Repo.insert()

      hotbar_slot
    end

    test "get_character_hotbar/1 returns all hotbar slots for a character" do
      character = character_fixture()
      item = item_fixture()
      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, item.id)

      {:ok, _hotbar_slot} = Items.set_hotbar_slot(character.id, 1, inventory_item.id)

      hotbar = Items.get_character_hotbar(character.id)
      assert length(hotbar) == 1
      assert List.first(hotbar).slot_number == 1
    end

    test "set_hotbar_slot/3 creates a new hotbar slot" do
      character = character_fixture()
      item = item_fixture()
      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, item.id)

      assert {:ok, %HotbarSlot{} = hotbar_slot} =
               Items.set_hotbar_slot(character.id, 1, inventory_item.id)

      assert hotbar_slot.character_id == character.id
      assert hotbar_slot.slot_number == 1
      assert hotbar_slot.item_id == item.id
      assert hotbar_slot.inventory_id == inventory_item.id
    end

    test "set_hotbar_slot/3 updates an existing hotbar slot" do
      character = character_fixture()
      item1 = item_fixture(%{@valid_attrs | name: "Item 1"})
      item2 = item_fixture(%{@valid_attrs | name: "Item 2"})

      {:ok, inventory_item1} = Items.add_item_to_inventory(character.id, item1.id)
      {:ok, inventory_item2} = Items.add_item_to_inventory(character.id, item2.id)

      {:ok, _} = Items.set_hotbar_slot(character.id, 1, inventory_item1.id)

      assert {:ok, %HotbarSlot{} = updated_slot} =
               Items.set_hotbar_slot(character.id, 1, inventory_item2.id)

      assert updated_slot.item_id == item2.id
      assert updated_slot.inventory_id == inventory_item2.id
    end

    test "clear_hotbar_slot/2 removes a hotbar slot" do
      character = character_fixture()
      item = item_fixture()
      {:ok, inventory_item} = Items.add_item_to_inventory(character.id, item.id)

      {:ok, _hotbar_slot} = Items.set_hotbar_slot(character.id, 1, inventory_item.id)
      assert {:ok, %HotbarSlot{}} = Items.clear_hotbar_slot(character.id, 1)

      hotbar = Items.get_character_hotbar(character.id)
      assert hotbar == []
    end
  end

  describe "tutorial items" do
    test "create_tutorial_key/0 creates a tutorial key in room (0,2,0)" do
      assert {:ok, %RoomItem{}} = Items.create_tutorial_key()

      # Check that the key exists in the room
      room_items = Items.get_room_items("0,2,0")
      assert length(room_items) == 1

      key_item = List.first(room_items).item
      assert key_item.name == "Tutorial Key"
    end

    test "create_tutorial_key/0 doesn't duplicate the key" do
      {:ok, first_result} = Items.create_tutorial_key()
      {:ok, second_result} = Items.create_tutorial_key()

      # Both should succeed, but second should return existing key
      assert match?(%RoomItem{}, first_result)
      assert match?(%RoomItem{}, second_result)

      # Should still only have one key in the room
      room_items = Items.get_room_items("0,2,0")
      assert length(room_items) == 1
    end
  end

  # Helper function for room items (since it's not in the public API)
  defp create_room_item(attrs) do
    %RoomItem{}
    |> RoomItem.changeset(attrs)
    |> Repo.insert()
  end
end
