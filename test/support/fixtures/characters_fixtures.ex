defmodule Shard.CharactersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Characters` context.
  """

  import Shard.UsersFixtures

  def valid_character_attributes(attrs \\ %{}) do
    user = user_fixture()

    Enum.into(attrs, %{
      name: "Test Character #{System.unique_integer([:positive])}",
      class: "warrior",
      race: "human",
      level: 1,
      health: 100,
      max_health: 100,
      mana: 50,
      max_mana: 50,
      strength: 10,
      dexterity: 10,
      intelligence: 10,
      constitution: 10,
      experience: 0,
      gold: 100,
      location: "Starting Town",
      description: "A test character",
      is_active: true,
      user_id: user.id
    })
  end

  def character_fixture(attrs \\ %{}) do
    {:ok, character} =
      attrs
      |> valid_character_attributes()
      |> Shard.Characters.create_character()

    character
  end
end
