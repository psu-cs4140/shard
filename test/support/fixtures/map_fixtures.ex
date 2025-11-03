defmodule Shard.MapFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Map` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    # Generate unique coordinates and name to avoid conflicts
    unique_id = System.unique_integer([:positive])
    
    default_attrs = %{
      name: "Test Room #{unique_id}",
      description: "A test room for the MUD game",
      x_coordinate: rem(unique_id, 1000),
      y_coordinate: div(unique_id, 1000),
      z_coordinate: 0,
      room_type: "standard",
      is_public: true
    }

    {:ok, room} =
      default_attrs
      |> Map.merge(attrs)
      |> Shard.Map.create_room()

    room
  end

  @doc """
  Generate a door.
  """
  def door_fixture(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])
    
    room1 = room_fixture(%{
      name: "Start Room #{unique_id}",
      x_coordinate: rem(unique_id, 1000),
      y_coordinate: div(unique_id, 1000)
    })
    
    room2 = room_fixture(%{
      name: "End Room #{unique_id}",
      x_coordinate: rem(unique_id, 1000) + 1,
      y_coordinate: div(unique_id, 1000)
    })

    default_attrs = %{
      from_room_id: room1.id,
      to_room_id: room2.id,
      direction: "north",
      door_type: "standard",
      is_locked: false
    }

    {:ok, door} =
      default_attrs
      |> Map.merge(attrs)
      |> Shard.Map.create_door()

    door
  end
end
