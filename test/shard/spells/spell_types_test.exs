defmodule Shard.Spells.SpellTypesTest do
  use Shard.DataCase

  alias Shard.Spells.SpellTypes

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(SpellTypes)
  end
end
