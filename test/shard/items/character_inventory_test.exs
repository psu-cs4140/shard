defmodule Shard.Items.CharacterInventoryTest do
  use Shard.DataCase

  alias Shard.Items.CharacterInventory

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(CharacterInventory)
  end
end
