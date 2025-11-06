defmodule Shard.Map.AdminStickTest do
  use Shard.DataCase

  alias Shard.Items
  alias Shard.Items.AdminStick

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
end
