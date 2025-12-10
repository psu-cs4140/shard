defmodule Shard.AchievementsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Achievements` context.
  """

  def valid_achievement_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Achievement #{System.unique_integer([:positive])}",
      description: "A test achievement for testing purposes",
      category: "general",
      points: 100,
      requirements: %{"level" => 5},
      hidden: false
    })
  end

  def achievement_fixture(attrs \\ %{}) do
    {:ok, achievement} =
      attrs
      |> valid_achievement_attributes()
      |> Shard.Achievements.create_achievement()

    achievement
  end
end
