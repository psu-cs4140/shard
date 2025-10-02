defmodule Shard.Weapons.SeedData.DamageTypesSeedsTest do
  use Shard.DataCase

  alias Shard.Weapons.SeedData.DamageTypesSeeds

  describe "data/0" do
    test "returns a list of damage type seed data" do
      data = DamageTypesSeeds.data()

      assert is_list(data)
      assert length(data) > 0

      Enum.each(data, fn item ->
        assert is_map(item)
        assert Map.has_key?(item, :name)
        assert is_binary(item.name)
      end)
    end
  end
end
