defmodule Shard.Weapons.SeedData.RaritiesSeedsTest do
  use Shard.DataCase

  alias Shard.Weapons.SeedData.RaritiesSeeds

  describe "data/0" do
    test "returns a list of rarity seed data" do
      data = RaritiesSeeds.data()

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
