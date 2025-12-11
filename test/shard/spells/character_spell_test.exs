defmodule Shard.Spells.CharacterSpellTest do
  use Shard.DataCase

  alias Shard.Spells.CharacterSpell

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(CharacterSpell)
  end
end
