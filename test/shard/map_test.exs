defmodule Shard.MapTest do
  use Shard.DataCase

  alias Shard.Map
  alias Shard.Map.{Room, Zone, Door}

  describe "zones" do
    @valid_zone_attrs %{
      name: "Test Zone",
      description: "A test zone for testing",
      slug: "test-zone",
      min_level: 1,
      max_level: 10
    }

    @invalid_zone_attrs %{name: nil, description: nil}

    test "list_zones/0 returns all zones" do
      zones = Map.list_zones()
      assert is_list(zones)
    end

    test "get_zone!/1 returns the zone with given id" do
      {:ok, zone} = Map.create_zone(@valid_zone_attrs)
      assert Map.get_zone!(zone.id).id == zone.id
    end

    test "create_zone/1 with valid data creates a zone" do
      assert {:ok, %Zone{} = zone} = Map.create_zone(@valid_zone_attrs)
      assert zone.name == "Test Zone"
      assert zone.description == "A test zone for testing"
      assert zone.min_level == 1
      assert zone.max_level == 10
    end

    test "create_zone/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Map.create_zone(@invalid_zone_attrs)
    end

    test "update_zone/2 with valid data updates the zone" do
      {:ok, zone} = Map.create_zone(@valid_zone_attrs)
      update_attrs = %{name: "Updated Zone", min_level: 5}

      assert {:ok, %Zone{} = zone} = Map.update_zone(zone, update_attrs)
      assert zone.name == "Updated Zone"
      assert zone.min_level == 5
    end

    test "delete_zone/1 deletes the zone" do
      {:ok, zone} = Map.create_zone(@valid_zone_attrs)
      assert {:ok, %Zone{}} = Map.delete_zone(zone)
      assert_raise Ecto.NoResultsError, fn -> Map.get_zone!(zone.id) end
    end

    test "validates level range" do
      invalid_attrs = %{
        name: "Test Zone",
        description: "Test",
        min_level: 10,
        max_level: 5
      }

      assert {:error, changeset} = Map.create_zone(invalid_attrs)
      assert %{max_level: ["must be greater than or equal to min_level"]} = errors_on(changeset)
    end
  end

  describe "rooms" do
    setup do
      {:ok, zone} = Map.create_zone(@valid_zone_attrs)
      %{zone: zone}
    end

    @valid_room_attrs %{
      name: "Test Room",
      description: "A test room",
      x_coordinate: 0,
      y_coordinate: 0,
      z_coordinate: 0
    }

    test "list_rooms/0 returns all rooms" do
      rooms = Map.list_rooms()
      assert is_list(rooms)
    end

    test "list_rooms_by_zone/1 returns rooms for a zone", %{zone: zone} do
      rooms = Map.list_rooms_by_zone(zone.id)
      assert is_list(rooms)
    end

    test "get_room!/1 returns the room with given id", %{zone: zone} do
      attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)
      {:ok, room} = Map.create_room(attrs)
      assert Map.get_room!(room.id).id == room.id
    end

    test "create_room/1 with valid data creates a room", %{zone: zone} do
      attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)
      assert {:ok, %Room{} = room} = Map.create_room(attrs)
      assert room.name == "Test Room"
      assert room.x_coordinate == 0
      assert room.y_coordinate == 0
      assert room.z_coordinate == 0
    end

    test "get_room_by_coordinates/4 finds room by coordinates", %{zone: zone} do
      attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)
      {:ok, room} = Map.create_room(attrs)

      found_room = Map.get_room_by_coordinates(zone.id, 0, 0, 0)
      assert found_room.id == room.id
    end
  end

  describe "doors" do
    setup do
      {:ok, zone} = Map.create_zone(@valid_zone_attrs)

      room1_attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)
      {:ok, room1} = Map.create_room(room1_attrs)

      room2_attrs = %{
        name: "Test Room 2",
        description: "Another test room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        zone_id: zone.id
      }

      {:ok, room2} = Map.create_room(room2_attrs)

      %{zone: zone, room1: room1, room2: room2}
    end

    test "create_door/1 creates a door between rooms", %{room1: room1, room2: room2} do
      door_attrs = %{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east"
      }

      assert {:ok, %Door{} = door} = Map.create_door(door_attrs)
      assert door.direction == "east"
      assert door.from_room_id == room1.id
      assert door.to_room_id == room2.id
    end

    test "opposite_direction/1 returns correct opposite", %{} do
      assert Door.opposite_direction("north") == "south"
      assert Door.opposite_direction("south") == "north"
      assert Door.opposite_direction("east") == "west"
      assert Door.opposite_direction("west") == "east"
      assert Door.opposite_direction("up") == "down"
      assert Door.opposite_direction("down") == "up"
      assert Door.opposite_direction("northeast") == "southwest"
      assert Door.opposite_direction("northwest") == "southeast"
      assert Door.opposite_direction("southeast") == "northwest"
      assert Door.opposite_direction("southwest") == "northeast"
      assert Door.opposite_direction("unknown") == "unknown"
    end
  end
end
