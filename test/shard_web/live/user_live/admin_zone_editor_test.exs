defmodule ShardWeb.UserLive.AdminZoneEditorTest do
  use Shard.DataCase

  alias ShardWeb.UserLive.AdminZoneEditor
  alias Shard.Map
  alias Shard.Items.AdminStick
  alias Shard.Items
  alias Shard.ZonesFixtures
  alias Shard.CharactersFixtures

  describe "admin zone editor functions" do
    setup do
      # Create a zone for testing
      zone = ZonesFixtures.zone_fixture(%{name: "Test Zone", slug: "test-zone"})
      
      # Create rooms for testing
      {:ok, room1} = Map.create_room(%{
        name: "Starting Room",
        description: "A room to start from",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        zone_id: zone.id
      })
      
      {:ok, room2} = Map.create_room(%{
        name: "North Room",
        description: "A room to the north",
        x_coordinate: 0,
        y_coordinate: 1,
        z_coordinate: 0,
        zone_id: zone.id
      })
      
      # Create a door between rooms
      {:ok, _door} = Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "north"
      })
      
      # Create a character for testing
      character = CharactersFixtures.character_fixture(%{
        name: "AdminCharacter",
        current_zone_id: zone.id
      })
      
      # Grant admin stick to character
      {:ok, _} = AdminStick.grant_admin_stick(character.id)
      
      %{
        zone: zone,
        room1: room1,
        room2: room2,
        character: character,
        game_state: %{
          character: character,
          player_position: {0, 0}
        }
      }
    end

    test "create_room_in_direction creates a new room and door", %{game_state: game_state} do
      # Test creating a room to the south (no existing room there)
      {response, _updated_game_state} = AdminZoneEditor.create_room_in_direction(game_state, "south")
      
      assert is_list(response)
      assert Enum.any?(response, fn msg -> String.contains?(msg, "Successfully created a new room") end)
      
      # Verify the room was created
      new_room = Map.get_room_by_coordinates(
        game_state.character.current_zone_id, 
        0, 
        -1, 
        0
      )
      
      assert new_room != nil
      assert new_room.name == "New Room"
      
      # Verify door was created
      door = Map.get_door_in_direction(game_state.room1.id, "south")
      assert door != nil
    end

    test "create_room_in_direction handles existing room", %{game_state: game_state} do
      # Try to create a room where one already exists (north)
      {response, _updated_game_state} = AdminZoneEditor.create_room_in_direction(game_state, "north")
      
      assert is_list(response)
      assert Enum.any?(response, fn msg -> String.contains?(msg, "A room already exists") end)
    end

    test "delete_room_in_direction removes a room", %{game_state: game_state, room2: room2} do
      # Test deleting the room to the north
      {response, _updated_game_state} = AdminZoneEditor.delete_room_in_direction(game_state, "north")
      
      assert is_list(response)
      assert Enum.any?(response, fn msg -> String.contains?(msg, "Successfully deleted the room") end)
      
      # Verify the room was deleted
      deleted_room = Map.get_room_by_coordinates(
        game_state.character.current_zone_id, 
        0, 
        1, 
        0
      )
      
      assert deleted_room == nil
    end

    test "create_door_in_direction creates a door to existing room", %{game_state: game_state, room2: room2} do
      # First delete the existing door to test creating a new one
      existing_door = Map.get_door_in_direction(game_state.room1.id, "north")
      if existing_door do
        {:ok, _} = Map.delete_door(existing_door)
      end
      
      # Test creating a door to the north room
      {response, _updated_game_state} = AdminZoneEditor.create_door_in_direction(game_state, "north")
      
      assert is_list(response)
      assert Enum.any?(response, fn msg -> String.contains?(msg, "Successfully created a door") end)
      
      # Verify door was created
      door = Map.get_door_in_direction(game_state.room1.id, "north")
      assert door != nil
    end

    test "delete_door_in_direction removes a door", %{game_state: game_state} do
      # Test deleting the door to the north
      {response, _updated_game_state} = AdminZoneEditor.delete_door_in_direction(game_state, "north")
      
      assert is_list(response)
      assert Enum.any?(response, fn msg -> String.contains?(msg, "Successfully deleted the door") end)
      
      # Verify the door was deleted
      door = Map.get_door_in_direction(game_state.room1.id, "north")
      assert door == nil
    end

    test "calculate_coordinates_from_direction returns correct coordinates" do
      # Test cardinal directions
      assert AdminZoneEditor.calculate_coordinates_from_direction({0, 0}, "north") == {0, 1}
      assert AdminZoneEditor.calculate_coordinates_from_direction({0, 0}, "south") == {0, -1}
      assert AdminZoneEditor.calculate_coordinates_from_direction({0, 0}, "east") == {1, 0}
      assert AdminZoneEditor.calculate_coordinates_from_direction({0, 0}, "west") == {-1, 0}
      
      # Test diagonal directions
      assert AdminZoneEditor.calculate_coordinates_from_direction({0, 0}, "northeast") == {1, 1}
      assert AdminZoneEditor.calculate_coordinates_from_direction({0, 0}, "northwest") == {-1, 1}
      assert AdminZoneEditor.calculate_coordinates_from_direction({0, 0}, "southeast") == {1, -1}
      assert AdminZoneEditor.calculate_coordinates_from_direction({0, 0}, "southwest") == {-1, -1}
    end
  end
end
