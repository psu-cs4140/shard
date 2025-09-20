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
  Generate a room with specific attributes.
  """
  def room_fixture(name, description) do
    room_fixture(%{name: name, description: description})
  end

  @doc """
  Generate multiple rooms.
  """
  def rooms_fixture(count) do
    for i <- 1..count do
      room_fixture(%{name: "Room #{i}", description: "Description for room #{i}"})
    end
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

  @doc """
  Generate a door between specific rooms.
  """
  def door_fixture(from_room, to_room, direction) do
    door_fixture(%{
      from_room_id: from_room.id,
      to_room_id: to_room.id,
      direction: direction
    })
  end

  @doc """
  Generate multiple doors connecting a list of rooms.
  """
  def doors_fixture(rooms, directions) do
    rooms
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.with_index()
    |> Enum.map(fn {[from_room, to_room], index} ->
      direction = Enum.at(directions, index, "north")
      door_fixture(from_room, to_room, direction)
    end)
  end

  @doc """
  Generate a simple linear map with connected rooms.
  """
  def linear_map_fixture(room_count) do
    directions = ["north", "east", "south", "west", "up", "down"]
    
    rooms = rooms_fixture(room_count)
    
    doors = 
      if room_count > 1 do
        doors_fixture(rooms, Enum.take(directions, room_count - 1))
      else
        []
      end
    
    %{rooms: rooms, doors: doors}
  end
end
