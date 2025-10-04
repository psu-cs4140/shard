defmodule Shard.CharactersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Characters` context.
  """

  alias Shard.Characters

  def valid_character_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Character",
      class: "warrior",
      race: "human"
    })
  end

  def character_fixture(attrs \\ %{}) do
    user = attrs[:user] || Shard.UsersFixtures.user_fixture()

    {:ok, character} =
      attrs
      |> valid_character_attributes()
      |> Map.put(:user_id, user.id)
      |> Characters.create_character()

    character
  end
end
