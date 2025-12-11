defmodule Shard.Skills.SkillNodeTest do
  use Shard.DataCase

  alias Shard.Skills.SkillNode

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(SkillNode)
  end
end
