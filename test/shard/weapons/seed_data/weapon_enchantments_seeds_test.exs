defmodule Shard.Weapons.SeedData.WeaponEnchantmentsSeedsTest do
  use Shard.DataCase

  alias Shard.Weapons.SeedData.WeaponEnchantmentsSeeds

  describe "data/0" do
    test "returns a list of weapon enchantment seed data" do
      data = WeaponEnchantmentsSeeds.data()

      assert is_list(data)
      assert length(data) > 0

      Enum.each(data, fn item ->
        assert is_map(item)
        assert Map.has_key?(item, :weapon_id)
        assert Map.has_key?(item, :enchantment_id)
        assert is_integer(item.weapon_id)
        assert is_integer(item.enchantment_id)
      end)
    end
  end
end
