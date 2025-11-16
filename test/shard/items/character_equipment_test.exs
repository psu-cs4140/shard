defmodule Shard.Items.CharacterEquipmentTest do
  use Shard.DataCase

  alias Shard.Items.CharacterEquipment
  alias Shard.Items
  alias Shard.Characters
  alias Shard.Repo

  describe "changeset/2" do
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

      {:ok, equippable_item} = Items.create_item(%{
        name: "Test Sword",
        description: "A test sword",
        item_type: "weapon",
        rarity: "common",
        value: 100,
        equippable: true,
        equipment_slot: "weapon",
        is_active: true
      })

      {:ok, non_equippable_item} = Items.create_item(%{
        name: "Test Potion",
        description: "A test potion",
        item_type: "consumable",
        rarity: "common",
        value: 50,
        equippable: false,
        is_active: true
      })

      %{
        character: character,
        equippable_item: equippable_item,
        non_equippable_item: non_equippable_item
      }
    end

    test "valid changeset with all required fields", %{character: character, equippable_item: item} do
      attrs = %{
        character_id: character.id,
        item_id: item.id,
        equipment_slot: "weapon"
      }

      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, attrs)

      assert changeset.valid?
      assert get_change(changeset, :character_id) == character.id
      assert get_change(changeset, :item_id) == item.id
      assert get_change(changeset, :equipment_slot) == "weapon"
    end

    test "invalid changeset when missing required fields" do
      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, %{})

      refute changeset.valid?
      assert %{character_id: ["can't be blank"]} = errors_on(changeset)
      assert %{item_id: ["can't be blank"]} = errors_on(changeset)
      assert %{equipment_slot: ["can't be blank"]} = errors_on(changeset)
    end

    test "invalid changeset with invalid equipment slot", %{character: character, equippable_item: item} do
      attrs = %{
        character_id: character.id,
        item_id: item.id,
        equipment_slot: "invalid_slot"
      }

      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, attrs)

      refute changeset.valid?
      assert %{equipment_slot: ["is invalid"]} = errors_on(changeset)
    end

    test "invalid changeset when item is not equippable", %{character: character, non_equippable_item: item} do
      attrs = %{
        character_id: character.id,
        item_id: item.id,
        equipment_slot: "weapon"
      }

      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, attrs)

      refute changeset.valid?
      assert %{item_id: ["is not equippable"]} = errors_on(changeset)
    end

    test "invalid changeset when equipment slot doesn't match item's slot", %{character: character, equippable_item: item} do
      attrs = %{
        character_id: character.id,
        item_id: item.id,
        equipment_slot: "head"  # item's slot is "weapon"
      }

      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, attrs)

      refute changeset.valid?
      assert %{equipment_slot: ["does not match item's equipment slot"]} = errors_on(changeset)
    end

    test "invalid changeset with non-existent item_id", %{character: character} do
      attrs = %{
        character_id: character.id,
        item_id: 99999,  # non-existent ID
        equipment_slot: "weapon"
      }

      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, attrs)

      refute changeset.valid?
      assert %{item_id: ["does not exist"]} = errors_on(changeset)
    end
  end

  describe "database constraints" do
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

      {:ok, item} = Items.create_item(%{
        name: "Test Sword",
        description: "A test sword",
        item_type: "weapon",
        rarity: "common",
        value: 100,
        equippable: true,
        equipment_slot: "weapon",
        is_active: true
      })

      %{character: character, item: item}
    end

    test "unique constraint on character_id and equipment_slot", %{character: character, item: item} do
      # Create first equipment
      {:ok, _equipment1} = 
        %CharacterEquipment{}
        |> CharacterEquipment.changeset(%{
          character_id: character.id,
          item_id: item.id,
          equipment_slot: "weapon"
        })
        |> Repo.insert()

      # Try to create second equipment with same character and slot
      {:error, changeset} = 
        %CharacterEquipment{}
        |> CharacterEquipment.changeset(%{
          character_id: character.id,
          item_id: item.id,
          equipment_slot: "weapon"
        })
        |> Repo.insert()

      assert %{character_id: ["has already been taken"]} = errors_on(changeset) ||
             %{equipment_slot: ["has already been taken"]} = errors_on(changeset)
    end

    test "foreign key constraint on character_id" do
      {:ok, item} = Items.create_item(%{
        name: "Test Item",
        description: "A test item",
        item_type: "weapon",
        rarity: "common",
        value: 100,
        equippable: true,
        equipment_slot: "weapon",
        is_active: true
      })

      {:error, changeset} = 
        %CharacterEquipment{}
        |> CharacterEquipment.changeset(%{
          character_id: 99999,  # non-existent character
          item_id: item.id,
          equipment_slot: "weapon"
        })
        |> Repo.insert()

      assert %{character_id: ["does not exist"]} = errors_on(changeset)
    end

    test "foreign key constraint on item_id", %{character: character} do
      {:error, changeset} = 
        %CharacterEquipment{}
        |> CharacterEquipment.changeset(%{
          character_id: character.id,
          item_id: 99999,  # non-existent item
          equipment_slot: "weapon"
        })
        |> Repo.insert()

      assert %{item_id: ["does not exist"]} = errors_on(changeset)
    end
  end

  describe "associations" do
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

      {:ok, item} = Items.create_item(%{
        name: "Test Sword",
        description: "A test sword",
        item_type: "weapon",
        rarity: "common",
        value: 100,
        equippable: true,
        equipment_slot: "weapon",
        is_active: true
      })

      {:ok, equipment} = 
        %CharacterEquipment{}
        |> CharacterEquipment.changeset(%{
          character_id: character.id,
          item_id: item.id,
          equipment_slot: "weapon"
        })
        |> Repo.insert()

      %{character: character, item: item, equipment: equipment}
    end

    test "belongs_to character association", %{equipment: equipment, character: character} do
      equipment = Repo.preload(equipment, :character)
      assert equipment.character.id == character.id
      assert equipment.character.name == character.name
    end

    test "belongs_to item association", %{equipment: equipment, item: item} do
      equipment = Repo.preload(equipment, :item)
      assert equipment.item.id == item.id
      assert equipment.item.name == item.name
    end
  end
end
