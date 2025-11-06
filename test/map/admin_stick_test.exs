defmodule Shard.Map.AdminStickTest do
  use Shard.DataCase

  alias Shard.Items
  alias Shard.Items.AdminStick

  describe "admin stick item" do
    test "admin stick item exists in database" do
      # Check that the admin stick item was created by migration
      admin_stick = AdminStick.get_admin_stick_item()
      assert admin_stick != nil
      assert admin_stick.name == "Admin Zone Editing Stick"
      assert admin_stick.description == "A magical stick that allows admins to modify zones"
      assert admin_stick.item_type == "tool"
      assert admin_stick.rarity == "legendary"
      assert admin_stick.equippable == false
      assert admin_stick.stackable == false
    end

    test "admin stick item is unique" do
      # Try to create another admin stick item with the same name
      attrs = %{
        name: "Admin Zone Editing Stick",
        description: "Duplicate admin stick",
        item_type: "tool",
        rarity: "common",
        equippable: true,
        stackable: true
      }

      # This should fail due to unique constraint on name
      case Items.create_item(attrs) do
        {:error, changeset} ->
          assert changeset.errors[:name] != nil
        {:ok, _item} ->
          # If it somehow succeeds, fail the test
          flunk("Should not be able to create duplicate admin stick")
      end
    end
  end
end
