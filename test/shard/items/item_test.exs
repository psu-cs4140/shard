defmodule Shard.Items.ItemTest do
  use Shard.DataCase

  alias Shard.Items.Item

  describe "MapField" do
    test "casts map values correctly" do
      assert Item.MapField.cast(%{"key" => "value"}) == {:ok, %{"key" => "value"}}
      assert Item.MapField.cast(%{}) == {:ok, %{}}
    end

    test "casts empty list to empty map" do
      assert Item.MapField.cast([]) == {:ok, %{}}
    end

    test "casts list to empty map" do
      assert Item.MapField.cast([1, 2, 3]) == {:ok, %{}}
    end

    test "returns error for invalid values" do
      assert Item.MapField.cast("string") == :error
      assert Item.MapField.cast(123) == :error
    end

    test "returns correct type" do
      assert Item.MapField.type() == :map
    end
  end
end
