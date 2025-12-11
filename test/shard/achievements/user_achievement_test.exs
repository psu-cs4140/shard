defmodule Shard.Achievements.UserAchievementTest do
  use Shard.DataCase

  alias Shard.Achievements.UserAchievement

  test "module exists and is accessible" do
    assert Code.ensure_loaded?(UserAchievement)
  end
end
