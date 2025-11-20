defmodule Shard.Seeds.EffectsSeederTest do
  use Shard.DataCase

  alias Shard.Seeds.EffectsSeeder
  alias Shard.Weapons.Effects
  alias Shard.Repo

  describe "run/0" do
    test "inserts effects from seed data" do
      # Mock the seed data
      seed_data = [
        %{name: "Poison", description: "Poison effect"},
        %{name: "Stun", description: "Stun effect"}
      ]

      # Mock the seed data module
      expect(Shard.Weapons.SeedData.EffectsSeeds, :data, fn -> seed_data end)

      # Run the seeder
      EffectsSeeder.run()

      # Verify the effects were inserted
      assert Repo.get_by(Effects, name: "Poison")
      assert Repo.get_by(Effects, name: "Stun")
    end

    test "does not insert duplicate effects" do
      # Create an existing effect
      existing_attrs = %{name: "Poison", description: "Poison effect"}
      %Effects{}
      |> Effects.changeset(existing_attrs)
      |> Repo.insert!()

      initial_count = Repo.aggregate(Effects, :count, :id)

      # Mock seed data with the same effect
      seed_data = [existing_attrs]
      expect(Shard.Weapons.SeedData.EffectsSeeds, :data, fn -> seed_data end)

      # Run the seeder
      EffectsSeeder.run()

      # Verify no duplicate was created
      final_count = Repo.aggregate(Effects, :count, :id)
      assert final_count == initial_count
    end
  end

  describe "insert_effect/1" do
    test "inserts new effect successfully" do
      attrs = %{name: "Burn", description: "Burn effect"}

      result = EffectsSeeder.insert_effect(attrs)

      assert %Effects{} = result
      assert result.name == "Burn"
      assert result.description == "Burn effect"
    end

    test "returns :already_exists for existing effect" do
      attrs = %{name: "Poison", description: "Poison effect"}

      # Insert the effect first
      %Effects{}
      |> Effects.changeset(attrs)
      |> Repo.insert!()

      # Try to insert again
      result = EffectsSeeder.insert_effect(attrs)

      assert result == :already_exists
    end
  end
end
