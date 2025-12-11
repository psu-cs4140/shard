defmodule Shard.Skills.CharacterSkillTest do
  use Shard.DataCase

  alias Shard.Skills.CharacterSkill

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(CharacterSkill)
  end
end
