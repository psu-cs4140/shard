defmodule Shard.Quests.QuestTest do
  use Shard.DataCase

  alias Shard.Quests.Quest

  describe "MapField" do
    test "casts map values correctly" do
      assert Quest.MapField.cast(%{"key" => "value"}) == {:ok, %{"key" => "value"}}
      assert Quest.MapField.cast(%{}) == {:ok, %{}}
    end

    test "casts empty list to empty map" do
      assert Quest.MapField.cast([]) == {:ok, %{}}
    end

    test "casts list to empty map" do
      assert Quest.MapField.cast([1, 2, 3]) == {:ok, %{}}
    end

    test "returns error for invalid values" do
      assert Quest.MapField.cast("string") == :error
      assert Quest.MapField.cast(123) == :error
    end

    test "returns correct type" do
      assert Quest.MapField.type() == :map
    end
  end
end
