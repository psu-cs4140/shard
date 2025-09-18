defmodule Shard.MapFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Map` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    {:ok, room} =
      attrs
      |> Enum.into(%{
        name: "Test Room",
        description: "A test room for the MUD game"
      })
      |> Shard.Map.create_room()

    room
  end

  @doc """
  Generate a door.
  """
  def door_fixture(attrs \\ %{}) do
    room1 = room_fixture(%{name: "Start Room"})
    room2 = room_fixture(%{name: "End Room"})

    {:ok, door} =
      attrs
      |> Enum.into(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "north"
      })
      |> Shard.Map.create_door()

    door
  end
end
