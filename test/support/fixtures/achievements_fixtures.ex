defmodule Shard.AchievementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Achievements` context.
  """

  alias Shard.Achievements

  def valid_achievement_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Achievement",
      description: "A test achievement for testing purposes",
      category: "test",
      points: 100,
      requirements: %{"level" => 5},
      is_hidden: false,
      is_repeatable: false
    })
  end

  def achievement_fixture(attrs \\ %{}) do
    {:ok, achievement} =
      attrs
      |> valid_achievement_attributes()
      |> Achievements.create_achievement()

    achievement
  end

  def valid_user_achievement_attributes(attrs \\ %{}) do
    achievement = achievement_fixture()
    user = Shard.UsersFixtures.user_fixture()

    Enum.into(attrs, %{
      user_id: user.id,
      achievement_id: achievement.id,
      earned_at: DateTime.utc_now(),
      progress: %{"current" => 1, "required" => 1}
    })
  end

  def user_achievement_fixture(attrs \\ %{}) do
    {:ok, user_achievement} =
      attrs
      |> valid_user_achievement_attributes()
      |> Achievements.create_user_achievement()

    user_achievement
  end
end
