defmodule Shard.Seeds.DamageTypesSeederTest do
  use Shard.DataCase

  alias Shard.Seeds.DamageTypesSeeder
  alias Shard.Weapons.DamageTypes
  alias Shard.Repo

  describe "run/0" do
    test "inserts damage types from seed data" do
      # Mock the seed data
      seed_data = [
        %{name: "Fire", description: "Fire damage"},
        %{name: "Ice", description: "Ice damage"}
      ]

      # Mock the seed data module
      expect(Shard.Weapons.SeedData.DamageTypesSeeds, :data, fn -> seed_data end)

      # Run the seeder
      DamageTypesSeederTest.run()

      # Verify the damage types were inserted
      assert Repo.get_by(DamageTypes, name: "Fire")
      assert Repo.get_by(DamageTypes, name: "Ice")
    end

    test "does not insert duplicate damage types" do
      # Create an existing damage type
      existing_attrs = %{name: "Fire", description: "Fire damage"}
      %DamageTypes{}
      |> DamageTypes.changeset(existing_attrs)
      |> Repo.insert!()

      initial_count = Repo.aggregate(DamageTypes, :count, :id)

      # Mock seed data with the same damage type
      seed_data = [existing_attrs]
      expect(Shard.Weapons.SeedData.DamageTypesSeeds, :data, fn -> seed_data end)

      # Run the seeder
      DamageTypesSeederTest.run()

      # Verify no duplicate was created
      final_count = Repo.aggregate(DamageTypes, :count, :id)
      assert final_count == initial_count
    end
  end

  describe "insert_damage_type/1" do
    test "inserts new damage type successfully" do
      attrs = %{name: "Lightning", description: "Lightning damage"}

      result = DamageTypesSeederTest.insert_damage_type(attrs)

      assert %DamageTypes{} = result
      assert result.name == "Lightning"
      assert result.description == "Lightning damage"
    end

    test "returns :already_exists for existing damage type" do
      attrs = %{name: "Fire", description: "Fire damage"}

      # Insert the damage type first
      %DamageTypes{}
      |> DamageTypes.changeset(attrs)
      |> Repo.insert!()

      # Try to insert again
      result = DamageTypesSeederTest.insert_damage_type(attrs)

      assert result == :already_exists
    end
  end
end
