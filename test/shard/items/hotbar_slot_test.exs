defmodule Shard.Items.HotbarSlotTest do
  use Shard.DataCase

  alias Shard.Items.HotbarSlot

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(HotbarSlot)
  end
end
