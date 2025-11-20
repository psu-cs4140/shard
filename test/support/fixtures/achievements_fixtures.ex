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
      hidden: false
    })
  end

  def achievement_fixture(attrs \\ %{}) do
    {:ok, achievement} =
      attrs
      |> valid_achievement_attributes()
      |> Achievements.create_achievement()

    achievement
  end

end
