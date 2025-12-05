defmodule Shard.MapTest do
  use Shard.DataCase

  alias Shard.Map
  alias Shard.Map.{Room, Door, Zone, PlayerPosition}

  describe "zones" do
    @valid_zone_attrs %{
      name: "Test Zone",
      slug: "test-zone",
      description: "A test zone for testing",
      zone_type: "standard",
      min_level: 1,
      max_level: 10
    }

    @invalid_zone_attrs %{name: nil, slug: nil}

    test "list_zones/0 returns all zones" do
      zone = zone_fixture()
      zones = Map.list_zones()
      assert length(zones) >= 1
      assert Enum.any?(zones, fn z -> z.id == zone.id end)
    end

    test "list_active_zones/0 returns only active zones ordered by display_order" do
      active_zone = zone_fixture(%{is_active: true, display_order: 1})
      inactive_zone = zone_fixture(%{is_active: false, display_order: 2, slug: "inactive-zone"})

      active_zones = Map.list_active_zones()
      active_ids = Enum.map(active_zones, & &1.id)

      assert active_zone.id in active_ids
      refute inactive_zone.id in active_ids
    end

    test "get_zone!/1 returns the zone with given id" do
      zone = zone_fixture()
      assert Map.get_zone!(zone.id).id == zone.id
    end

    test "get_zone_by_slug/1 returns zone with given slug" do
      zone = zone_fixture()
      assert Map.get_zone_by_slug(zone.slug).id == zone.id
    end

    test "get_zone_by_slug/1 returns nil for non-existent slug" do
      assert Map.get_zone_by_slug("non-existent") == nil
    end

    test "create_zone/1 with valid data creates a zone" do
      assert {:ok, %Zone{} = zone} = Map.create_zone(@valid_zone_attrs)
      assert zone.name == "Test Zone"
      assert zone.slug == "test-zone"
      assert zone.zone_type == "standard"
    end

    test "create_zone/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Map.create_zone(@invalid_zone_attrs)
    end

    test "update_zone/2 with valid data updates the zone" do
      zone = zone_fixture()
      update_attrs = %{name: "Updated Zone", description: "Updated description"}

      assert {:ok, %Zone{} = zone} = Map.update_zone(zone, update_attrs)
      assert zone.name == "Updated Zone"
      assert zone.description == "Updated description"
    end

    test "update_zone/2 with invalid data returns error changeset" do
      zone = zone_fixture()
      assert {:error, %Ecto.Changeset{}} = Map.update_zone(zone, @invalid_zone_attrs)
      assert zone == Map.get_zone!(zone.id)
    end

    test "delete_zone/1 deletes the zone" do
      zone = zone_fixture()
      assert {:ok, %Zone{}} = Map.delete_zone(zone)
      assert_raise Ecto.NoResultsError, fn -> Map.get_zone!(zone.id) end
    end

    test "change_zone/1 returns a zone changeset" do
      zone = zone_fixture()
      assert %Ecto.Changeset{} = Map.change_zone(zone)
    end
  end

  describe "rooms" do
    @valid_room_attrs %{
      name: "Test Room",
      description: "A test room",
      x_coordinate: 0,
      y_coordinate: 0,
      z_coordinate: 0
    }

    @invalid_room_attrs %{name: nil}

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      rooms = Map.list_rooms()
      assert length(rooms) >= 1
      assert Enum.any?(rooms, fn r -> r.id == room.id end)
    end

    test "list_rooms_by_zone/1 returns rooms in specific zone" do
      zone = zone_fixture()
      room1 = room_fixture(%{zone_id: zone.id})
      room2 = room_fixture(%{zone_id: zone.id, name: "Room 2", x_coordinate: 1})

      other_zone = zone_fixture(%{slug: "other-zone"})
      _other_room = room_fixture(%{zone_id: other_zone.id, name: "Other Room", x_coordinate: 2})

      zone_rooms = Map.list_rooms_by_zone(zone.id)
      zone_room_ids = Enum.map(zone_rooms, & &1.id)

      assert room1.id in zone_room_ids
      assert room2.id in zone_room_ids
      assert length(zone_rooms) == 2
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Map.get_room!(room.id).id == room.id
    end

    test "get_room_by_coordinates/4 returns room at coordinates in zone" do
      zone = zone_fixture()
      room = room_fixture(%{zone_id: zone.id, x_coordinate: 5, y_coordinate: 10, z_coordinate: 2})

      found_room = Map.get_room_by_coordinates(zone.id, 5, 10, 2)
      assert found_room.id == room.id
    end

    test "get_room_by_coordinates/3 defaults z to 0" do
      zone = zone_fixture()
      room = room_fixture(%{zone_id: zone.id, x_coordinate: 3, y_coordinate: 4})

      found_room = Map.get_room_by_coordinates(zone.id, 3, 4)
      assert found_room.id == room.id
    end

    test "create_room/1 with valid data creates a room" do
      zone = zone_fixture()
      attrs = Map.put(@valid_room_attrs, :zone_id, zone.id)

      assert {:ok, %Room{} = room} = Map.create_room(attrs)
      assert room.name == "Test Room"
      assert room.x_coordinate == 0
      assert room.y_coordinate == 0
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Map.create_room(@invalid_room_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      update_attrs = %{name: "Updated Room", description: "Updated description"}

      assert {:ok, %Room{} = room} = Map.update_room(room, update_attrs)
      assert room.name == "Updated Room"
      assert room.description == "Updated description"
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Map.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Map.get_room!(room.id) end
    end
  end

  describe "doors" do
    @valid_door_attrs %{
      direction: "north",
      door_type: "standard",
      is_locked: false
    }

    test "list_doors/0 returns all doors" do
      door = door_fixture()
      doors = Map.list_doors()
      assert length(doors) >= 1
      assert Enum.any?(doors, fn d -> d.id == door.id end)
    end

    test "get_door!/1 returns the door with given id" do
      door = door_fixture()
      assert Map.get_door!(door.id).id == door.id
    end

    test "create_door/1 with valid data creates a door and return door" do
      zone = zone_fixture()
      from_room = room_fixture(%{zone_id: zone.id, x_coordinate: 0, y_coordinate: 0})
      to_room = room_fixture(%{zone_id: zone.id, x_coordinate: 0, y_coordinate: 1, name: "North Room"})

      attrs = Map.merge(@valid_door_attrs, %{
        from_room_id: from_room.id,
        to_room_id: to_room.id
      })

      assert {:ok, %Door{} = door} = Map.create_door(attrs)
      assert door.direction == "north"
      assert door.from_room_id == from_room.id
      assert door.to_room_id == to_room.id

      # Check that return door was created
      return_door = Map.get_door_in_direction(to_room.id, "south")
      assert return_door != nil
      assert return_door.from_room_id == to_room.id
      assert return_door.to_room_id == from_room.id
    end

    test "get_doors_from_room/1 returns doors leading from room" do
      door = door_fixture()
      doors = Map.get_doors_from_room(door.from_room_id)
      assert length(doors) >= 1
      assert Enum.any?(doors, fn d -> d.id == door.id end)
    end

    test "get_doors_to_room/1 returns doors leading to room" do
      door = door_fixture()
      doors = Map.get_doors_to_room(door.to_room_id)
      assert length(doors) >= 1
      assert Enum.any?(doors, fn d -> d.id == door.id end)
    end

    test "get_door_in_direction/2 finds door in specific direction" do
      door = door_fixture()
      found_door = Map.get_door_in_direction(door.from_room_id, door.direction)
      assert found_door.id == door.id
    end

    test "get_adjacent_rooms/1 returns connected rooms" do
      zone = zone_fixture()
      center_room = room_fixture(%{zone_id: zone.id, x_coordinate: 0, y_coordinate: 0})
      north_room = room_fixture(%{zone_id: zone.id, x_coordinate: 0, y_coordinate: 1, name: "North Room"})
      south_room = room_fixture(%{zone_id: zone.id, x_coordinate: 0, y_coordinate: -1, name: "South Room"})

      # Create doors
      Map.create_door(%{
        from_room_id: center_room.id,
        to_room_id: north_room.id,
        direction: "north"
      })

      Map.create_door(%{
        from_room_id: south_room.id,
        to_room_id: center_room.id,
        direction: "north"
      })

      adjacent_rooms = Map.get_adjacent_rooms(center_room.id)
      adjacent_ids = Enum.map(adjacent_rooms, & &1.id)

      assert north_room.id in adjacent_ids
      assert south_room.id in adjacent_ids
    end

    test "delete_door/1 deletes door and return door" do
      door = door_fixture()
      return_door = Map.get_return_door(door)

      assert {:ok, _} = Map.delete_door(door)
      assert_raise Ecto.NoResultsError, fn -> Map.get_door!(door.id) end

      if return_door do
        assert_raise Ecto.NoResultsError, fn -> Map.get_door!(return_door.id) end
      end
    end
  end

  describe "player positions" do
    setup do
      user = user_fixture()
      character = character_fixture(%{user_id: user.id})
      zone = zone_fixture()
      room = room_fixture(%{zone_id: zone.id})

      %{character: character, zone: zone, room: room}
    end

    test "get_player_position/2 returns nil for new player", %{character: character, zone: zone} do
      assert Map.get_player_position(character.id, zone.id) == nil
    end

    test "update_player_position/3 creates new position", %{character: character, zone: zone, room: room} do
      assert {:ok, %PlayerPosition{} = position} = Map.update_player_position(character.id, zone.id, room)
      assert position.character_id == character.id
      assert position.zone_id == zone.id
      assert position.room_id == room.id
      assert position.x_coordinate == room.x_coordinate
      assert position.y_coordinate == room.y_coordinate
    end

    test "update_player_position/3 updates existing position", %{character: character, zone: zone, room: room} do
      # Create initial position
      {:ok, _position} = Map.update_player_position(character.id, zone.id, room)

      # Create new room and update position
      new_room = room_fixture(%{zone_id: zone.id, x_coordinate: 5, y_coordinate: 5, name: "New Room"})
      assert {:ok, %PlayerPosition{} = updated_position} = Map.update_player_position(character.id, zone.id, new_room)

      assert updated_position.room_id == new_room.id
      assert updated_position.x_coordinate == 5
      assert updated_position.y_coordinate == 5

      # Should only have one position record for this character/zone
      positions = Map.get_player_positions(character.id)
      zone_positions = Enum.filter(positions, &(&1.zone_id == zone.id))
      assert length(zone_positions) == 1
    end

    test "get_player_last_room/2 returns last known room", %{character: character, zone: zone, room: room} do
      assert Map.get_player_last_room(character.id, zone.id) == nil

      Map.update_player_position(character.id, zone.id, room)
      last_room = Map.get_player_last_room(character.id, zone.id)
      assert last_room.id == room.id
    end

    test "get_zone_starting_room/1 returns first room in zone", %{zone: zone, room: room} do
      starting_room = Map.get_zone_starting_room(zone.id)
      assert starting_room.id == room.id
    end

    test "get_player_entry_room/2 returns starting room for new player", %{character: character, zone: zone, room: room} do
      entry_room = Map.get_player_entry_room(character.id, zone.id)
      assert entry_room.id == room.id
    end

    test "get_player_entry_room/2 returns last room for returning player", %{character: character, zone: zone, room: room} do
      # Update player position
      Map.update_player_position(character.id, zone.id, room)

      # Create new room
      new_room = room_fixture(%{zone_id: zone.id, x_coordinate: 10, y_coordinate: 10, name: "Last Room"})
      Map.update_player_position(character.id, zone.id, new_room)

      entry_room = Map.get_player_entry_room(character.id, zone.id)
      assert entry_room.id == new_room.id
    end
  end

  # Helper functions
  defp zone_fixture(attrs \\ %{}) do
    unique_slug = "test-zone-#{System.unique_integer([:positive])}"

    attrs =
      Enum.into(attrs, %{
        name: "Test Zone",
        slug: unique_slug,
        description: "A test zone",
        zone_type: "standard"
      })

    {:ok, zone} = Map.create_zone(attrs)
    zone
  end

  defp room_fixture(attrs \\ %{}) do
    zone = attrs[:zone_id] && Repo.get!(Zone, attrs[:zone_id]) || zone_fixture()

    unique_name = "Test Room #{System.unique_integer([:positive])}"

    attrs =
      Enum.into(attrs, %{
        name: unique_name,
        description: "A test room",
        zone_id: zone.id,
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0
      })

    {:ok, room} = Map.create_room(attrs)
    room
  end

  defp door_fixture(attrs \\ %{}) do
    zone = zone_fixture()
    from_room = room_fixture(%{zone_id: zone.id, x_coordinate: 0, y_coordinate: 0})
    to_room = room_fixture(%{zone_id: zone.id, x_coordinate: 1, y_coordinate: 0, name: "East Room"})

    attrs =
      Enum.into(attrs, %{
        from_room_id: from_room.id,
        to_room_id: to_room.id,
        direction: "east",
        door_type: "standard"
      })

    {:ok, door} = Map.create_door(attrs)
    door
  end

  defp user_fixture do
    unique_email = "user#{System.unique_integer([:positive])}@example.com"

    {:ok, user} =
      Shard.Users.register_user(%{
        email: unique_email,
        password: "password123password123"
      })

    user
  end

  defp character_fixture(attrs \\ %{}) do
    user = attrs[:user_id] && Repo.get!(Shard.Users.User, attrs[:user_id]) || user_fixture()

    attrs =
      Enum.into(attrs, %{
        name: "Test Character #{System.unique_integer([:positive])}",
        class: "warrior",
        race: "human",
        user_id: user.id
      })

    {:ok, character} = Shard.Characters.create_character(attrs)
    character
  end
end
