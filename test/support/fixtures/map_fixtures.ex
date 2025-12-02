defmodule Shard.MapFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Map` context.
  """

  @doc """
  Generate a test zone.
  """
  def zone_fixture(attrs \\ %{}) do
    unique_id = System.unique_integer([:positive])

    {:ok, zone} =
      attrs
      |> Enum.into(%{
        name: "Test Zone #{unique_id}",
        slug: "test-zone-#{unique_id}",
        description: "A test zone for the MUD game"
      })
      |> Shard.Map.create_zone()

    zone
  end

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    # Create a zone if zone_id is not provided
    zone = 
      case Map.get(attrs, :zone_id) do
        nil -> zone_fixture()
        zone_id when is_integer(zone_id) -> Shard.Map.get_zone!(zone_id)
        _ -> zone_fixture()
      end

    {:ok, room} =
      attrs
      |> Enum.into(%{
        name: "Test Room",
        description: "A test room for the MUD game",
        zone_id: zone.id
      })
      |> Shard.Map.create_room()

    room
  end

  @doc """
  Generate a door.
  """
  def door_fixture(attrs \\ %{}) do
    # Create rooms in the same zone
    zone = zone_fixture()
    room1 = room_fixture(%{name: "Start Room", zone_id: zone.id})
    room2 = room_fixture(%{name: "End Room", zone_id: zone.id})

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
