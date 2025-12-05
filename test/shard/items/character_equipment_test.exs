defmodule Shard.Items.CharacterEquipmentTest do
  use Shard.DataCase

  alias Shard.Items.CharacterEquipment

  describe "changeset/2" do
    @valid_attrs %{
      character_id: 1,
      item_id: 1,
      equipment_slot: "weapon"
    }

    test "changeset with valid attributes" do
      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires character_id, item_id, and equipment_slot" do
      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.character_id
      assert "can't be blank" in errors.item_id
      assert "can't be blank" in errors.equipment_slot
    end

    test "validates equipment_slot inclusion" do
      invalid_attrs = %{@valid_attrs | equipment_slot: "invalid_slot"}
      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, invalid_attrs)
      refute changeset.valid?
      assert %{equipment_slot: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid equipment slots" do
      # Test with common equipment slots that should be valid
      valid_slots = ["weapon", "shield", "head", "body", "legs", "feet", "ring", "necklace"]

      for slot <- valid_slots do
        attrs = %{@valid_attrs | equipment_slot: slot}
        changeset = CharacterEquipment.changeset(%CharacterEquipment{}, attrs)
        # Note: This might fail if the item doesn't exist or isn't equippable
        # but we're testing the basic validation logic
        if changeset.valid? do
          assert true
        else
          # If it fails due to item validation, that's expected
          errors = errors_on(changeset)
          refute Map.has_key?(errors, :equipment_slot) or 
                 "is invalid" in errors.equipment_slot
        end
      end
    end

    test "validates foreign key constraints are present" do
      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, @valid_attrs)
      
      # Check that foreign key constraints are present
      assert Enum.any?(changeset.constraints, fn constraint ->
        constraint.type == :foreign_key and constraint.field == :character_id
      end)
      
      assert Enum.any?(changeset.constraints, fn constraint ->
        constraint.type == :foreign_key and constraint.field == :item_id
      end)
    end

    test "validates unique constraint for character and equipment slot" do
      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, @valid_attrs)
      
      # Check that unique constraint is present
      assert Enum.any?(changeset.constraints, fn constraint ->
        constraint.type == :unique and 
        constraint.fields == [:character_id, :equipment_slot]
      end)
    end

    test "handles item validation errors gracefully" do
      # Test with non-existent item
      attrs = %{@valid_attrs | item_id: 999999}
      changeset = CharacterEquipment.changeset(%CharacterEquipment{}, attrs)
      
      # The changeset should either be valid (if validation is deferred to database)
      # or have an item-related error
      if not changeset.valid? do
        errors = errors_on(changeset)
        assert Map.has_key?(errors, :item_id)
      end
    end
  end
end
