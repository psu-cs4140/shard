defmodule Shard.Map.AdminStickTest do
  use Shard.DataCase

  alias Shard.Items
  alias Shard.Items.AdminStick
  alias Shard.Characters
  alias Shard.Users
  alias Shard.UsersFixtures

  describe "admin stick item" do
    test "creates admin stick item through migration" do
      # Run the migration up
      Ecto.Migrator.up(Shard.Repo, 20251102000000, Shard.Repo.Migrations.CreateAdminStickItem)

      # Check that the admin stick item was created
      admin_stick = AdminStick.get_admin_stick_item()
      assert admin_stick != nil
      assert admin_stick.name == "Admin Zone Editing Stick"
      assert admin_stick.description == "A magical stick that allows admins to modify zones"
      assert admin_stick.item_type == "tool"
      assert admin_stick.rarity == "legendary"
      assert admin_stick.equippable == false
      assert admin_stick.stackable == false
      assert admin_stick.attributes["zone_editing"] == true
    end

    test "does not create duplicate admin stick item" do
      # Run the migration twice
      Ecto.Migrator.up(Shard.Repo, 20251102000000, Shard.Repo.Migrations.CreateAdminStickItem)
      Ecto.Migrator.up(Shard.Repo, 20251102000000, Shard.Repo.Migrations.CreateAdminStickItem)

      # Count how many admin stick items exist
      admin_sticks =
        from(i in Items.Item, where: i.name == "Admin Zone Editing Stick")
        |> Shard.Repo.all()

      # Should only have one
      assert length(admin_sticks) == 1
    end
  end

  describe "granting admin stick to characters" do
    setup do
      # Create an admin user
      admin_user = UsersFixtures.admin_user_fixture()
      
      # Create a regular user
      regular_user = UsersFixtures.user_fixture()
      
      # Create characters for both users
      {:ok, admin_character} = Characters.create_character(admin_user, %{name: "AdminChar"})
      {:ok, regular_character} = Characters.create_character(regular_user, %{name: "RegularChar"})
      
      # Make sure the admin stick exists
      AdminStick.create_admin_stick_item()
      
      %{
        admin_user: admin_user,
        regular_user: regular_user,
        admin_character: admin_character,
        regular_character: regular_character
      }
    end

    test "grants admin stick to admin character", %{admin_character: admin_character} do
      # Grant the admin stick
      assert {:ok, _} = AdminStick.grant_admin_stick_to_character(admin_character)

      # Check that the character now has the admin stick
      assert AdminStick.has_admin_stick?(admin_character) == true
    end

    test "does not grant admin stick to regular character", %{regular_character: regular_character} do
      # Try to grant the admin stick to a regular character
      assert {:error, "Character is not an admin"} = AdminStick.grant_admin_stick_to_character(regular_character)

      # Check that the character does not have the admin stick
      assert AdminStick.has_admin_stick?(regular_character) == false
    end

    test "does not grant duplicate admin stick", %{admin_character: admin_character} do
      # Grant the admin stick once
      assert {:ok, _} = AdminStick.grant_admin_stick_to_character(admin_character)

      # Try to grant it again
      assert {:ok, "Character already has Admin Stick"} = AdminStick.grant_admin_stick_to_character(admin_character)

      # Check inventory - should still only have one
      inventory = Items.get_character_inventory(admin_character.id)
      admin_stick = AdminStick.get_admin_stick_item()
      
      admin_stick_count = 
        inventory
        |> Enum.filter(fn ci -> ci.item_id == admin_stick.id end)
        |> Enum.count()

      assert admin_stick_count == 1
    end
  end
end
