defmodule Shard.MonstersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Monsters` context.
  """

  def valid_monster_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Monster #{System.unique_integer([:positive])}",
      race: "orc",
      level: 5,
      health: 100,
      max_health: 100,
      attack_damage: 15,
      xp_amount: 50,
      description: "A fearsome test monster",
      location_id: nil
    })
  end

  def monster_fixture(attrs \\ %{}) do
    {:ok, monster} =
      attrs
      |> valid_monster_attributes()
      |> Shard.Monsters.create_monster()

    monster
  end
end
