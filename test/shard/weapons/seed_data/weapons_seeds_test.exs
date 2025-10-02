defmodule Shard.Weapons.SeedData.WeaponsSeedsTest do
  use Shard.DataCase

  alias Shard.Weapons.SeedData.WeaponsSeeds

  describe "data/0" do
    test "returns a list of weapon seed data" do
      data = WeaponsSeeds.data()

      assert is_list(data)
      assert length(data) > 0

      Enum.each(data, fn item ->
        assert is_map(item)
        assert Map.has_key?(item, :name)
        assert Map.has_key?(item, :damage)
        assert Map.has_key?(item, :gold_value)
        assert Map.has_key?(item, :description)
        assert Map.has_key?(item, :weapon_class_id)
        assert Map.has_key?(item, :rarity_id)
        assert is_binary(item.name)
        assert is_integer(item.damage)
        assert is_integer(item.gold_value)
        assert is_binary(item.description)
        assert is_integer(item.weapon_class_id)
        assert is_integer(item.rarity_id)
      end)
    end
  end
end
