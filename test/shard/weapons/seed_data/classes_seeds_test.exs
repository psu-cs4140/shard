defmodule Shard.Weapons.SeedData.ClassesSeedsTest do
  use Shard.DataCase

  alias Shard.Weapons.SeedData.ClassesSeeds

  describe "data/0" do
    test "returns a list of class seed data" do
      data = ClassesSeeds.data()

      assert is_list(data)
      assert length(data) > 0

      Enum.each(data, fn item ->
        assert is_map(item)
        assert Map.has_key?(item, :name)
        assert Map.has_key?(item, :damage_type_id)
        assert is_binary(item.name)
        assert is_integer(item.damage_type_id)
      end)
    end
  end
end
