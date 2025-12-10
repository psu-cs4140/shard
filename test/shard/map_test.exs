defmodule Shard.MapTest do
  use Shard.DataCase

  alias Shard.Map
  alias Shard.Map.{Room, Zone, Door}

  describe "zones" do
    @invalid_zone_attrs %{name: nil, description: nil}


    test "list_zones/0 returns all zones" do
      {:ok, zone} = Map.create_zone(valid_zone_attrs())
      zones = Map.list_zones()
      assert length(zones) >= 1
      assert Enum.any?(zones, fn z -> z.id == zone.id end)
    end

    test "get_zone!/1 returns the zone with given id" do
      {:ok, zone} = Map.create_zone(valid_zone_attrs())
      assert Map.get_zone!(zone.id).id == zone.id
    end

    test "get_zone!/1 raises when zone not found" do
      assert_raise Ecto.NoResultsError, fn -> Map.get_zone!(999) end
    end

    test "create_zone/1 with valid data creates a zone" do
      attrs = valid_zone_attrs()
      assert {:ok, %Zone{} = zone} = Map.create_zone(attrs)
      assert zone.name == attrs.name
      assert zone.description == attrs.description
      assert zone.min_level == 1
      assert zone.max_level == 10
    end

    test "create_zone/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Map.create_zone(@invalid_zone_attrs)
    end

    test "update_zone/2 with valid data updates the zone" do
      {:ok, zone} = Map.create_zone(valid_zone_attrs())

      update_attrs = %{
        name: "Updated Zone #{System.unique_integer([:positive])}",
        description: "Updated description",
        min_level: 5,
        max_level: 15
      }

      assert {:ok, %Zone{} = updated_zone} = Map.update_zone(zone, update_attrs)
      assert updated_zone.name == update_attrs.name
      assert updated_zone.description == update_attrs.description
      assert updated_zone.min_level == 5
      assert updated_zone.max_level == 15
    end

    test "update_zone/2 with invalid data returns error changeset" do
      {:ok, zone} = Map.create_zone(valid_zone_attrs())
      assert {:error, %Ecto.Changeset{}} = Map.update_zone(zone, @invalid_zone_attrs)

      refreshed_zone = Map.get_zone!(zone.id)
      assert refreshed_zone.name == zone.name
      assert refreshed_zone.description == zone.description
    end

    test "delete_zone/1 deletes the zone" do
      {:ok, zone} = Map.create_zone(valid_zone_attrs())
      assert {:ok, %Zone{}} = Map.delete_zone(zone)
      assert_raise Ecto.NoResultsError, fn -> Map.get_zone!(zone.id) end
    end

    test "change_zone/1 returns a zone changeset" do
      {:ok, zone} = Map.create_zone(valid_zone_attrs())
      assert %Ecto.Changeset{} = Map.change_zone(zone)
    end

    test "get_zone_by_slug/1 returns zone with given slug" do
      slug = "findable-zone-#{System.unique_integer([:positive])}"
      attrs = Enum.into([slug: slug], valid_zone_attrs())
      {:ok, zone} = Map.create_zone(attrs)

      found_zone = Map.get_zone_by_slug(slug)
      assert found_zone.id == zone.id
      assert found_zone.slug == slug
    end

    test "get_zone_by_slug/1 returns nil for non-existent zone" do
      assert Map.get_zone_by_slug("non-existent-zone") == nil
    end
  end

  describe "rooms" do
    setup do
      {:ok, zone} = Map.create_zone(valid_zone_attrs())
      %{zone: zone}
    end

    @invalid_room_attrs %{name: nil, description: nil, x: nil, y: nil, z: nil}

    defp valid_room_attrs(zone_id) do
      %{
        name: "Test Room #{System.unique_integer([:positive])}",
        description: "A test room for testing purposes",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        zone_id: zone_id
      }
    end

    test "list_rooms/0 returns all rooms", %{zone: zone} do
      {:ok, room} = Map.create_room(valid_room_attrs(zone.id))
      rooms = Map.list_rooms()
      assert length(rooms) >= 1
      assert Enum.any?(rooms, fn r -> r.id == room.id end)
    end

    test "get_room!/1 returns the room with given id", %{zone: zone} do
      {:ok, room} = Map.create_room(valid_room_attrs(zone.id))
      assert Map.get_room!(room.id).id == room.id
    end

    test "get_room!/1 raises when room not found" do
      assert_raise Ecto.NoResultsError, fn -> Map.get_room!(999) end
    end

    test "create_room/1 with valid data creates a room", %{zone: zone} do
      attrs = valid_room_attrs(zone.id)
      assert {:ok, %Room{} = room} = Map.create_room(attrs)
      assert room.name == attrs.name
      assert room.description == attrs.description
      assert room.x_coordinate == 0
      assert room.y_coordinate == 0
      assert room.z_coordinate == 0
      assert room.zone_id == zone.id
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Map.create_room(@invalid_room_attrs)
    end

    test "update_room/2 with valid data updates the room", %{zone: zone} do
      {:ok, room} = Map.create_room(valid_room_attrs(zone.id))

      update_attrs = %{
        name: "Updated Room #{System.unique_integer([:positive])}",
        description: "Updated description",
        x_coordinate: 5,
        y_coordinate: 10
      }

      assert {:ok, %Room{} = updated_room} = Map.update_room(room, update_attrs)
      assert updated_room.name == update_attrs.name
      assert updated_room.description == update_attrs.description
      assert updated_room.x_coordinate == 5
      assert updated_room.y_coordinate == 10
    end

    test "update_room/2 with invalid data returns error changeset", %{zone: zone} do
      {:ok, room} = Map.create_room(valid_room_attrs(zone.id))
      assert {:error, %Ecto.Changeset{}} = Map.update_room(room, @invalid_room_attrs)

      refreshed_room = Map.get_room!(room.id)
      assert refreshed_room.name == room.name
      assert refreshed_room.description == room.description
    end

    test "delete_room/1 deletes the room", %{zone: zone} do
      {:ok, room} = Map.create_room(valid_room_attrs(zone.id))
      assert {:ok, %Room{}} = Map.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Map.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset", %{zone: zone} do
      {:ok, room} = Map.create_room(valid_room_attrs(zone.id))
      assert %Ecto.Changeset{} = Map.change_room(room)
    end

    test "get_room_by_coordinates/3 returns room at specific coordinates", %{zone: zone} do
      attrs = Enum.into([x_coordinate: 3, y_coordinate: 7, z_coordinate: 1], valid_room_attrs(zone.id))
      {:ok, room} = Map.create_room(attrs)

      found_room = Map.get_room_by_coordinates(zone.id, 3, 7, 1)
      assert found_room.id == room.id
      assert found_room.x_coordinate == 3
      assert found_room.y_coordinate == 7
      assert found_room.z_coordinate == 1
    end

    test "get_room_by_coordinates/3 returns nil for non-existent coordinates", %{zone: zone} do
      assert Map.get_room_by_coordinates(zone.id, 999, 999, 999) == nil
    end

    test "get_rooms_in_zone/1 returns rooms in specific zone", %{zone: zone} do
      {:ok, room1} = Map.create_room(valid_room_attrs(zone.id))
      {:ok, room2} = Map.create_room(Enum.into([x_coordinate: 1, y_coordinate: 1], valid_room_attrs(zone.id)))

      rooms_in_zone = Map.list_rooms()
      zone_rooms = Enum.filter(rooms_in_zone, fn room -> room.zone_id == zone.id end)
      assert length(zone_rooms) >= 2

      room_ids = Enum.map(zone_rooms, & &1.id)
      assert room1.id in room_ids
      assert room2.id in room_ids
    end

    test "get_adjacent_rooms/3 returns rooms adjacent to coordinates", %{zone: zone} do
      # Create a room at (0,0,0)
      {:ok, center_room} = Map.create_room(valid_room_attrs(zone.id))

      # Create adjacent rooms
      {:ok, north_room} =
        Map.create_room(Enum.into([x_coordinate: 0, y_coordinate: 1, z_coordinate: 0], valid_room_attrs(zone.id)))

      {:ok, east_room} =
        Map.create_room(Enum.into([x_coordinate: 1, y_coordinate: 0, z_coordinate: 0], valid_room_attrs(zone.id)))

      # Create doors to connect the rooms
      {:ok, _door1} = Map.create_door(%{
        direction: "north",
        from_room_id: center_room.id,
        to_room_id: north_room.id,
        is_locked: false
      })

      {:ok, _door2} = Map.create_door(%{
        direction: "east", 
        from_room_id: center_room.id,
        to_room_id: east_room.id,
        is_locked: false
      })

      adjacent_rooms = Map.get_adjacent_rooms(center_room.id)
      adjacent_ids = Enum.map(adjacent_rooms, & &1.id)

      assert north_room.id in adjacent_ids
      assert east_room.id in adjacent_ids
    end
  end

  describe "doors" do
    setup do
      {:ok, zone} = Map.create_zone(valid_zone_attrs())

      {:ok, room1} =
        Map.create_room(%{
          name: "Room 1 #{System.unique_integer([:positive])}",
          description: "First room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          zone_id: zone.id
        })

      {:ok, room2} =
        Map.create_room(%{
          name: "Room 2 #{System.unique_integer([:positive])}",
          description: "Second room",
          x_coordinate: 1,
          y_coordinate: 0,
          z_coordinate: 0,
          zone_id: zone.id
        })

      %{zone: zone, room1: room1, room2: room2}
    end

    @invalid_door_attrs %{direction: nil, from_room_id: nil, to_room_id: nil}

    defp valid_door_attrs(from_room_id, to_room_id) do
      %{
        direction: "east",
        from_room_id: from_room_id,
        to_room_id: to_room_id,
        is_locked: false
      }
    end

    test "list_doors/0 returns all doors", %{room1: room1, room2: room2} do
      {:ok, door} = Map.create_door(valid_door_attrs(room1.id, room2.id))
      doors = Map.list_doors()
      assert length(doors) >= 1
      assert Enum.any?(doors, fn d -> d.id == door.id end)
    end

    test "get_door!/1 returns the door with given id", %{room1: room1, room2: room2} do
      {:ok, door} = Map.create_door(valid_door_attrs(room1.id, room2.id))
      assert Map.get_door!(door.id).id == door.id
    end

    test "get_door!/1 raises when door not found" do
      assert_raise Ecto.NoResultsError, fn -> Map.get_door!(999) end
    end

    test "create_door/1 with valid data creates a door", %{room1: room1, room2: room2} do
      attrs = valid_door_attrs(room1.id, room2.id)
      assert {:ok, %Door{} = door} = Map.create_door(attrs)
      assert door.direction == "east"
      assert door.from_room_id == room1.id
      assert door.to_room_id == room2.id
      assert door.is_locked == false
    end

    test "create_door/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Map.create_door(@invalid_door_attrs)
    end

    test "update_door/2 with valid data updates the door", %{room1: room1, room2: room2} do
      {:ok, door} = Map.create_door(valid_door_attrs(room1.id, room2.id))

      update_attrs = %{
        direction: "west",
        is_locked: true
      }

      assert {:ok, %Door{} = updated_door} = Map.update_door(door, update_attrs)
      assert updated_door.direction == "west"
      assert updated_door.is_locked == true
    end

    test "update_door/2 with invalid data returns error changeset", %{room1: room1, room2: room2} do
      {:ok, door} = Map.create_door(valid_door_attrs(room1.id, room2.id))
      assert {:error, %Ecto.Changeset{}} = Map.update_door(door, @invalid_door_attrs)

      refreshed_door = Map.get_door!(door.id)
      assert refreshed_door.direction == door.direction
      assert refreshed_door.from_room_id == door.from_room_id
    end

    test "delete_door/1 deletes the door", %{room1: room1, room2: room2} do
      {:ok, door} = Map.create_door(valid_door_attrs(room1.id, room2.id))
      assert {:ok, %Door{}} = Map.delete_door(door)
      assert_raise Ecto.NoResultsError, fn -> Map.get_door!(door.id) end
    end

    test "change_door/1 returns a door changeset", %{room1: room1, room2: room2} do
      {:ok, door} = Map.create_door(valid_door_attrs(room1.id, room2.id))
      assert %Ecto.Changeset{} = Map.change_door(door)
    end

    test "get_doors_from_room/1 returns doors from specific room", %{room1: room1, room2: room2} do
      {:ok, door} = Map.create_door(valid_door_attrs(room1.id, room2.id))

      doors = Map.list_doors()
      doors_from_room = Enum.filter(doors, fn d -> d.from_room_id == room1.id end)
      assert length(doors_from_room) >= 1
      assert Enum.any?(doors_from_room, fn d -> d.id == door.id end)
    end

    test "get_door_in_direction/2 returns door in specific direction from room", %{
      room1: room1,
      room2: room2
    } do
      {:ok, door} = Map.create_door(valid_door_attrs(room1.id, room2.id))

      found_door = Map.get_door_in_direction(room1.id, "east")
      assert found_door.id == door.id
      assert found_door.direction == "east"
    end

    test "get_door_in_direction/2 returns nil for non-existent direction", %{room1: room1} do
      assert Map.get_door_in_direction(room1.id, "north") == nil
    end

    test "opposite_direction/1 returns correct opposite directions" do
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

  describe "Zone changeset" do
    test "validates required fields" do
      changeset = Zone.changeset(%Zone{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.slug
    end

    test "validates level range" do
      attrs = %{name: "Test Zone", description: "Test", min_level: 10, max_level: 5}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{max_level: ["must be greater than or equal to min_level"]} = errors_on(changeset)
    end

    test "accepts valid zone data" do
      attrs = valid_zone_attrs()
      changeset = Zone.changeset(%Zone{}, attrs)
      assert changeset.valid?
    end
  end

  describe "Room changeset" do
    test "validates required fields" do
      changeset = Room.changeset(%Room{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
    end

    test "accepts valid room data" do
      {:ok, zone} = Map.create_zone(valid_zone_attrs())
      attrs = valid_room_attrs(zone.id)
      changeset = Room.changeset(%Room{}, attrs)
      assert changeset.valid?
    end
  end

  describe "Door changeset" do
    test "validates required fields" do
      changeset = Door.changeset(%Door{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.direction
      assert "can't be blank" in errors.from_room_id
      assert "can't be blank" in errors.to_room_id
    end

    test "validates direction inclusion" do
      attrs = %{
        direction: "invalid_direction",
        from_room_id: 1,
        to_room_id: 2
      }

      changeset = Door.changeset(%Door{}, attrs)
      refute changeset.valid?
      assert %{direction: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid door data" do
      attrs = %{
        direction: "north",
        from_room_id: 1,
        to_room_id: 2,
        is_locked: false
      }

      changeset = Door.changeset(%Door{}, attrs)
      assert changeset.valid?
    end
  end

  defp valid_zone_attrs do
    %{
      name: "Test Zone #{System.unique_integer([:positive])}",
      slug: "test-zone-#{System.unique_integer([:positive])}",
      description: "A test zone for testing purposes",
      min_level: 1,
      max_level: 10
    }
  end
end
