defmodule Shard.Weapons.SeedData.WeaponEffectsSeedsTest do
  use Shard.DataCase

  alias Shard.Weapons.SeedData.WeaponEffectsSeeds

  describe "data/0" do
    test "returns a list of weapon effect seed data" do
      data = WeaponEffectsSeeds.data()

      assert is_list(data)
      assert length(data) > 0

      Enum.each(data, fn item ->
        assert is_map(item)
        assert Map.has_key?(item, :weapon_id)
        assert Map.has_key?(item, :effect_id)
        assert is_integer(item.weapon_id)
        assert is_integer(item.effect_id)
      end)
    end
  end
end
