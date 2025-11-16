defmodule Shard.ItemsEquipmentTest do
  use Shard.DataCase

  alias Shard.Items
  alias Shard.Characters

  describe "equipment functions" do
    setup do
      {:ok, character} = Characters.create_character(%{
        name: "Test Character",
        level: 1,
        health: 100,
        max_health: 100,
        mana: 50,
        max_mana: 50,
        experience: 0,
        strength: 10,
        dexterity: 10,
        constitution: 10,
        intelligence: 10,
        wisdom: 10,
        charisma: 10
      })

      {:ok, weapon} = Items.create_item(%{
        name: "Test Sword",
        description: "A test sword",
        item_type: "weapon",
        rarity: "common",
        value: 100,
        equippable: true,
        equipment_slot: "weapon",
        is_active: true
      })

      {:ok, helmet} = Items.create_item(%{
        name: "Test Helmet",
        description: "A test helmet",
        item_type: "head",
        rarity: "common",
        value: 50,
        equippable: true,
        equipment_slot: "head",
        is_active: true
      })

      {:ok, non_equippable} = Items.create_item(%{
        name: "Test Potion",
        description: "A test potion",
        item_type: "consumable",
        rarity: "common",
        value: 25,
        equippable: false,
        is_active: true
      })

      %{
        character: character,
        weapon: weapon,
        helmet: helmet,
        non_equippable: non_equippable
      }
    end

    test "get_equipped_items/1 returns empty map when no items equipped", %{character: character} do
      equipped_items = Items.get_equipped_items(character.id)
      assert equipped_items == %{}
    end

    test "equip_item_to_slot/2 successfully equips an item", %{character: character, weapon: weapon} do
      {:ok, equipment} = Items.equip_item_to_slot(character.id, weapon.id)

      assert equipment.character_id == character.id
      assert equipment.item_id == weapon.id
      assert equipment.equipment_slot == "weapon"

      equipped_items = Items.get_equipped_items(character.id)
      assert equipped_items["weapon"].id == weapon.id
    end

    test "equip_item_to_slot/2 fails when item doesn't exist", %{character: character} do
      {:error, reason} = Items.equip_item_to_slot(character.id, 99999)
      assert reason == :item_not_found
    end

    test "equip_item_to_slot/2 fails when item is not equippable", %{character: character, non_equippable: item} do
      {:error, reason} = Items.equip_item_to_slot(character.id, item.id)
      assert reason == :item_not_equippable
    end

    test "equip_item_to_slot/2 fails when item is already equipped", %{character: character, weapon: weapon} do
      {:ok, _equipment} = Items.equip_item_to_slot(character.id, weapon.id)
      
      {:error, reason} = Items.equip_item_to_slot(character.id, weapon.id)
      assert reason == :already_equipped
    end

    test "equip_item_to_slot/2 replaces existing item in same slot", %{character: character, weapon: weapon, helmet: helmet} do
      # Create another weapon to test slot replacement
      {:ok, weapon2} = Items.create_item(%{
        name: "Test Axe",
        description: "A test axe",
        item_type: "weapon",
        rarity: "common",
        value: 120,
        equippable: true,
        equipment_slot: "weapon",
        is_active: true
      })

      # Equip first weapon
      {:ok, _equipment1} = Items.equip_item_to_slot(character.id, weapon.id)
      
      # Equip helmet (different slot)
      {:ok, _equipment2} = Items.equip_item_to_slot(character.id, helmet.id)

      # Equip second weapon (should replace first weapon)
      {:ok, equipment3} = Items.equip_item_to_slot(character.id, weapon2.id)

      assert equipment3.item_id == weapon2.id
      assert equipment3.equipment_slot == "weapon"

      equipped_items = Items.get_equipped_items(character.id)
      assert equipped_items["weapon"].id == weapon2.id
      assert equipped_items["head"].id == helmet.id
      assert map_size(equipped_items) == 2
    end

    test "unequip_item_from_slot/2 successfully unequips an item", %{character: character, weapon: weapon} do
      {:ok, _equipment} = Items.equip_item_to_slot(character.id, weapon.id)
      
      {:ok, _deleted} = Items.unequip_item_from_slot(character.id, "weapon")

      equipped_items = Items.get_equipped_items(character.id)
      assert equipped_items == %{}
    end

    test "unequip_item_from_slot/2 fails when no item equipped in slot", %{character: character} do
      {:error, reason} = Items.unequip_item_from_slot(character.id, "weapon")
      assert reason == :not_equipped
    end

    test "item_equipped?/2 returns true when item is equipped", %{character: character, weapon: weapon} do
      refute Items.item_equipped?(character.id, weapon.id)
      
      {:ok, _equipment} = Items.equip_item_to_slot(character.id, weapon.id)
      
      assert Items.item_equipped?(character.id, weapon.id)
    end

    test "item_equipped?/2 returns false when item is not equipped", %{character: character, weapon: weapon} do
      refute Items.item_equipped?(character.id, weapon.id)
    end

    test "get_equipped_items/1 returns all equipped items", %{character: character, weapon: weapon, helmet: helmet} do
      {:ok, _equipment1} = Items.equip_item_to_slot(character.id, weapon.id)
      {:ok, _equipment2} = Items.equip_item_to_slot(character.id, helmet.id)

      equipped_items = Items.get_equipped_items(character.id)
      
      assert equipped_items["weapon"].id == weapon.id
      assert equipped_items["head"].id == helmet.id
      assert map_size(equipped_items) == 2
    end
  end
end
