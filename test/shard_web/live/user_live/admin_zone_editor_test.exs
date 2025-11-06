defmodule ShardWeb.UserLive.AdminZoneEditorTest do
  use Shard.DataCase

  alias ShardWeb.UserLive.AdminZoneEditor
  alias Shard.Map
  alias Shard.Items.AdminStick
  alias Shard.UsersFixtures
  alias Shard.Characters

  describe "admin zone editor functions" do
    setup do
      # Create a zone for testing using direct Map functions
      {:ok, zone} = Map.create_zone(%{
        name: "Test Zone", 
        slug: "test-zone",
        description: "A test zone for admin editing",
        is_active: true
      })
      
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
      
      # Create a user and character for testing
      user = UsersFixtures.user_fixture()
      {:ok, character} = Characters.create_character(%{
        name: "AdminCharacter",
        user_id: user.id,
        class: "warrior",
        race: "human",
        level: 1,
        health: 100,
        mana: 50,
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        constitution: 10,
        current_zone_id: zone.id
      })
      
      # Grant admin stick to character
      {:ok, _} = AdminStick.grant_admin_stick(character.id)
      
      %{
        zone: zone,
        room1: room1,
        _room2: room2,
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

    test "delete_room_in_direction removes a room", %{game_state: game_state, _room2: _room2} do
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

    test "create_door_in_direction creates a door to existing room", %{game_state: game_state, _room2: _room2} do
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
  end
end
