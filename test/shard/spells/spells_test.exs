defmodule Shard.Spells.SpellsTest do
  use Shard.DataCase

  alias Shard.Spells.Spells

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(Spells)
  end
end
