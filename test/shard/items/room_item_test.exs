defmodule Shard.Items.RoomItemTest do
  use Shard.DataCase

  alias Shard.Items.RoomItem

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(RoomItem)
  end
end
