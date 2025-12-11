defmodule Shard.MapTest do
  use Shard.DataCase

  alias Shard.Map
  alias Shard.Map.{Zone, Room, Door}

  describe "zones" do
    @valid_zone_attrs %{
      name: "Test Zone",
      description: "A test zone",
      min_level: 1,
      max_level: 10
    }

    @invalid_zone_attrs %{name: nil, description: nil}

    test "list_zones/0 returns all zones" do
      {:ok, zone} = Map.create_zone(@valid_zone_attrs)
      zones = Map.list_zones()
      assert zone in zones
    end

    test "get_zone!/1 returns the zone with given id" do
      {:ok, zone} = Map.create_zone(@valid_zone_attrs)
      assert Map.get_zone!(zone.id) == zone
    end

    test "create_zone/1 with valid data creates a zone" do
      assert {:ok, %Zone{} = zone} = Map.create_zone(@valid_zone_attrs)
      assert zone.name == "Test Zone"
      assert zone.description == "A test zone"
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

    test "list_rooms/0 returns all rooms", %{zone: zone} do
      attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)
      {:ok, room} = Map.create_room(attrs)
      rooms = Map.list_rooms()
      assert room in rooms
    end

    test "get_room!/1 returns the room with given id", %{zone: zone} do
      attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)
      {:ok, room} = Map.create_room(attrs)
      assert Map.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room", %{zone: zone} do
      attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)
      assert {:ok, %Room{} = room} = Map.create_room(attrs)
      assert room.name == "Test Room"
      assert room.x_coordinate == 0
      assert room.y_coordinate == 0
      assert room.z_coordinate == 0
    end

    test "list_rooms_by_zone/1 returns rooms for specific zone", %{zone: zone} do
      attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)
      {:ok, room} = Map.create_room(attrs)
      
      # Create another zone and room
      {:ok, other_zone} = Map.create_zone(%{@valid_zone_attrs | name: "Other Zone"})
      other_attrs = Map.put(@valid_room_attrs, :zone_id, other_zone.id)
      {:ok, _other_room} = Map.create_room(other_attrs)

      zone_rooms = Map.list_rooms_by_zone(zone.id)
      assert room in zone_rooms
      assert length(zone_rooms) == 1
    end
  end

  describe "doors" do
    setup do
      {:ok, zone} = Map.create_zone(@valid_zone_attrs)
      
      room1_attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)
      {:ok, room1} = Map.create_room(room1_attrs)
      
      room2_attrs = %{@valid_room_attrs | name: "Room 2", x_coordinate: 1, zone_id: zone.id}
      {:ok, room2} = Map.create_room(room2_attrs)
      
      %{zone: zone, room1: room1, room2: room2}
    end

    test "create_door/1 creates a door between rooms", %{room1: room1, room2: room2} do
      door_attrs = %{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "north",
        is_locked: false
      }

      assert {:ok, %Door{} = door} = Map.create_door(door_attrs)
      assert door.from_room_id == room1.id
      assert door.to_room_id == room2.id
      assert door.direction == "north"
      assert door.is_locked == false
    end

    test "get_doors_from_room/1 returns doors from a room", %{room1: room1, room2: room2} do
      door_attrs = %{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "north",
        is_locked: false
      }
      {:ok, door} = Map.create_door(door_attrs)

      doors = Map.get_doors_from_room(room1.id)
      assert door in doors
    end
  end
end
