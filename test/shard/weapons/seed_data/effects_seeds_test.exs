defmodule Shard.Weapons.SeedData.EffectsSeedsTest do
  use Shard.DataCase

  alias Shard.Weapons.SeedData.EffectsSeeds

  describe "data/0" do
    test "returns a list of effect seed data" do
      data = EffectsSeeds.data()

      assert is_list(data)
      assert length(data) > 0

      Enum.each(data, fn item ->
        assert is_map(item)
        assert Map.has_key?(item, :name)
        assert Map.has_key?(item, :modifier_type)
        assert Map.has_key?(item, :modifier_value)
        assert is_binary(item.name)
        assert is_binary(item.modifier_type)
        assert is_integer(item.modifier_value)
      end)
    end
  end
end
