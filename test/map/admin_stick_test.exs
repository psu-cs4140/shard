defmodule Shard.Map.AdminStickTest do
  use Shard.DataCase

  alias Shard.Items
  alias Shard.Items.AdminSticks
  alias Shard.Characters
  alias Shard.UsersFixtures

  describe "admin stick item" do
    setup do
      :ok
    end

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

    test "admin_stick? function works correctly" do
      admin_stick = AdminStick.get_admin_stick_item()
      assert AdminStick.admin_stick?(admin_stick) == true

      # Create a different item
      {:ok, other_item} =
        Items.create_item(%{
          name: "Regular Stick",
          description: "Just a regular stick",
          item_type: "tool",
          rarity: "common",
          equippable: false,
          stackable: true,
          usable: false,
          is_active: true
        })

      assert AdminStick.admin_stick?(other_item) == false
      assert AdminStick.admin_stick?(nil) == false

      # Clean up
      Items.delete_item(other_item)
    end
  end

  describe "admin stick functions" do
    setup do
      # Make sure the admin stick exists
      case AdminStick.get_admin_stick_item() do
        nil ->
          # If it doesn't exist, create it
          {:ok, _item} =
            Items.create_item(%{
              name: "Admin Zone Editing Stick",
              description: "A magical stick that allows admins to modify zones",
              item_type: "tool",
              rarity: "legendary",
              equippable: false,
              stackable: false,
              usable: true,
              is_active: true
            })

        _ ->
          :ok
      end

      # Create a user and character for testing
      user = UsersFixtures.user_fixture()
      unique_name = "Test Character #{System.system_time(:millisecond)}"

      # Create character without triggering zone-related code
      character_attrs = %{
        name: unique_name,
        user_id: user.id,
        class: "warrior",
        race: "human",
        level: 1,
        health: 100,
        mana: 50,
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        constitution: 10
      }

      # Insert character directly to avoid any zone-related triggers
      character =
        %Shard.Characters.Character{}
        |> Shard.Characters.Character.changeset(character_attrs)
        |> Shard.Repo.insert!()

      %{character: character}
    end

    test "grant_admin_stick adds stick to character inventory", %{character: character} do
      # Grant the admin stick to the character
      result = AdminStick.grant_admin_stick(character.id)
      assert {:ok, _} = result

      # Check that the character now has the admin stick using our special function
      assert AdminStick.has_admin_stick?(character.id) == true

      # Check that the inventory entry exists using our count function
      admin_stick_count = AdminStick.count_admin_sticks(character.id)
      assert admin_stick_count == 1
    end

    test "grant_admin_stick does not add duplicate stick", %{character: character} do
      # Grant the admin stick once
      {:ok, _} = AdminStick.grant_admin_stick(character.id)

      # Try to grant it again
      result = AdminStick.grant_admin_stick(character.id)
      assert {:ok, "Character already has Admin Stick"} = result

      # Check inventory - should still only have one using our count function
      admin_stick_count = AdminStick.count_admin_sticks(character.id)
      assert admin_stick_count == 1
    end

    test "has_admin_stick? returns false when character doesn't have stick", %{
      character: character
    } do
      # Check that character doesn't have admin stick initially
      assert AdminStick.has_admin_stick?(character.id) == false
    end

    test "has_admin_stick? returns false when admin stick doesn't exist" do
      # Create a character first
      user = UsersFixtures.user_fixture()
      unique_name = "Test Character #{System.system_time(:millisecond) + 1}"

      character_attrs = %{
        name: unique_name,
        user_id: user.id,
        class: "warrior",
        race: "human",
        level: 1,
        health: 100,
        mana: 50,
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        constitution: 10
      }

      # Insert character directly to avoid any zone-related triggers
      character =
        %Shard.Characters.Character{}
        |> Shard.Characters.Character.changeset(character_attrs)
        |> Shard.Repo.insert!()

      # Temporarily delete the admin stick item if it exists
      case AdminStick.get_admin_stick_item() do
        nil ->
          # Already doesn't exist, proceed with test
          :ok

        admin_stick ->
          # Delete it for this test
          {:ok, _} = Items.delete_item(admin_stick)
      end

      # Check that has_admin_stick? returns false when item doesn't exist
      assert AdminStick.has_admin_stick?(character.id) == false
    end
  end
end
