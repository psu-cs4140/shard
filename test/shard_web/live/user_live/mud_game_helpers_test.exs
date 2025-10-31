defmodule ShardWeb.UserLive.MudGameHelpersTest do
  use Shard.DataCase, async: false
  use ShardWeb.ConnCase

  alias ShardWeb.UserLive.MudGameHelpers
  alias Shard.Characters
  alias Shard.Items
  alias Shard.Npcs

  describe "get_character_from_params/1" do
    test "returns error when no character_id in params" do
      params = %{}
      assert {:error, :no_character} = MudGameHelpers.get_character_from_params(params)
    end

    test "returns error when character_id is nil" do
      params = %{"character_id" => nil}
      assert {:error, :no_character} = MudGameHelpers.get_character_from_params(params)
    end

    test "returns character when valid character_id provided" do
      user = Shard.UsersFixtures.user_fixture()
      {:ok, character} = Characters.create_character(%{
        user_id: user.id,
        name: "Test Character",
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        constitution: 10
      })

      params = %{"character_id" => character.id}
      assert {:ok, returned_character} = MudGameHelpers.get_character_from_params(params)
      assert returned_character.id == character.id
    end

    test "returns error when character_id does not exist" do
      params = %{"character_id" => Ecto.UUID.generate()}
      assert {:error, :no_character} = MudGameHelpers.get_character_from_params(params)
    end
  end

  describe "get_character_name/2" do
    test "returns character name when no character_name in params and character exists" do
      character = %{name: "Test Character"}
      params = %{}
      
      result = MudGameHelpers.get_character_name(params, character)
      assert result == "Test Character"
    end

    test "returns 'Unknown' when no character_name in params and no character" do
      params = %{}
      
      result = MudGameHelpers.get_character_name(params, nil)
      assert result == "Unknown"
    end

    test "returns decoded character_name from params when provided" do
      params = %{"character_name" => "Test%20Character"}
      character = %{name: "Other Name"}
      
      result = MudGameHelpers.get_character_name(params, character)
      assert result == "Test Character"
    end

    test "handles character_name being nil in params" do
      character = %{name: "Test Character"}
      params = %{"character_name" => nil}
      
      result = MudGameHelpers.get_character_name(params, character)
      assert result == "Test Character"
    end
  end

  describe "load_character_with_associations/1" do
    test "loads character with associations successfully" do
      user = Shard.UsersFixtures.user_fixture()
      {:ok, character} = Characters.create_character(%{
        user_id: user.id,
        name: "Test Character",
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        constitution: 10
      })

      assert {:ok, loaded_character} = MudGameHelpers.load_character_with_associations(character)
      assert loaded_character.id == character.id
      # The preloaded associations should be loaded (even if empty)
      assert is_list(loaded_character.character_inventories)
      assert is_list(loaded_character.hotbar_slots)
    end

    test "returns original character when loading fails" do
      # Create a character with an invalid ID to simulate failure
      character = %{id: Ecto.UUID.generate(), name: "Test"}
      
      assert {:ok, returned_character} = MudGameHelpers.load_character_with_associations(character)
      assert returned_character == character
    end
  end

  describe "setup_tutorial_content/1" do
    test "sets up tutorial content for tutorial_terrain map" do
      # Mock the dependent functions to avoid actual database operations
      # This test verifies the function completes without error
      result = MudGameHelpers.setup_tutorial_content("tutorial_terrain")
      assert result == :ok
    end

    test "does nothing for non-tutorial maps" do
      result = MudGameHelpers.setup_tutorial_content("other_map")
      assert result == :ok
    end
  end

  describe "add_message/2" do
    test "adds message to terminal output" do
      terminal_state = %{
        output: ["Previous message"],
        command_history: [],
        current_command: ""
      }
      
      result = MudGameHelpers.add_message(terminal_state, "New message")
      
      assert result.output == ["Previous message", "New message", ""]
    end

    test "adds message to empty terminal output" do
      terminal_state = %{
        output: [],
        command_history: [],
        current_command: ""
      }
      
      result = MudGameHelpers.add_message(terminal_state, "First message")
      
      assert result.output == ["First message", ""]
    end
  end

  describe "posn_to_room_channel/1" do
    test "converts position tuple to room channel string" do
      position = {5, 10}
      result = MudGameHelpers.posn_to_room_channel(position)
      assert result == "room:5,10"
    end

    test "handles negative coordinates" do
      position = {-3, -7}
      result = MudGameHelpers.posn_to_room_channel(position)
      assert result == "room:-3,-7"
    end

    test "handles zero coordinates" do
      position = {0, 0}
      result = MudGameHelpers.posn_to_room_channel(position)
      assert result == "room:0,0"
    end
  end

  describe "initialize_game_state/3" do
    test "initializes complete game state with valid character" do
      user = Shard.UsersFixtures.user_fixture()
      {:ok, character} = Characters.create_character(%{
        user_id: user.id,
        name: "Test Character",
        strength: 15,
        dexterity: 12,
        intelligence: 14,
        constitution: 13,
        health: 120,
        mana: 80,
        level: 2,
        experience: 150
      })

      # Load character with associations first
      {:ok, loaded_character} = MudGameHelpers.load_character_with_associations(character)

      map_id = "test_map"
      character_name = "Test Character"

      assert {:ok, assigns} = MudGameHelpers.initialize_game_state(loaded_character, map_id, character_name)

      # Verify the structure of returned assigns
      assert Map.has_key?(assigns, :game_state)
      assert Map.has_key?(assigns, :terminal_state)
      assert Map.has_key?(assigns, :chat_state)
      assert Map.has_key?(assigns, :modal_state)
      assert assigns.character_name == character_name
      assert assigns.active_tab == "terminal"

      # Verify game_state structure
      game_state = assigns.game_state
      assert Map.has_key?(game_state, :player_position)
      assert Map.has_key?(game_state, :map_data)
      assert Map.has_key?(game_state, :character)
      assert Map.has_key?(game_state, :player_stats)
      assert game_state.map_id == map_id
      assert game_state.character.id == character.id

      # Verify player stats calculations
      stats = game_state.player_stats
      assert stats.constitution == 13
      assert stats.max_health == 100 + (13 - 10) * 5  # 115
      assert stats.max_stamina == 100 + 12 * 2  # 124
      assert stats.max_mana == 50 + 14 * 3  # 92
      assert stats.level == 2
      assert stats.experience == 150

      # Verify terminal state
      terminal_state = assigns.terminal_state
      assert is_list(terminal_state.output)
      assert length(terminal_state.output) > 0
      assert is_list(terminal_state.command_history)
      assert terminal_state.current_command == ""

      # Verify chat state
      chat_state = assigns.chat_state
      assert is_list(chat_state.messages)
      assert chat_state.current_message == ""

      # Verify modal state
      modal_state = assigns.modal_state
      assert modal_state.show == false
      assert modal_state.type == 0
      assert is_nil(modal_state.completion_message)
    end
  end
end
