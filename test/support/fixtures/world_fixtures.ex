defmodule Shard.WorldFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.World` context.
  """

  @doc """
  Generate a unique monster name.
  """
  def unique_monster_name, do: "some name#{System.unique_integer([:positive])}"

  @doc """
  Generate a unique monster slug.
  """
  def unique_monster_slug, do: "some slug#{System.unique_integer([:positive])}"

  @doc """
  Generate a monster.
  """
  def monster_fixture(attrs \\ %{}) do
    {:ok, monster} =
      attrs
      |> Enum.into(%{
        ai: "passive",
        attack: 42,
        defense: 42,
        description: "some description",
        element: "neutral",
        hp: 42,
        level: 42,
        name: unique_monster_name(),
        slug: unique_monster_slug(),
        spawn_rate: 42,
        species: "some species",
        speed: 42,
        xp_drop: 42
      })
      |> Shard.World.create_monster()

    monster
  end
end
