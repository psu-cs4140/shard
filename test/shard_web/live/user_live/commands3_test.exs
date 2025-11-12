defmodule ShardWeb.UserLive.Commands3Test do
  use Shard.DataCase, async: true
  alias ShardWeb.UserLive.Commands3

  describe "parse_poke_command/1" do
    test "parses poke command with quoted character name" do
      assert {:ok, "Character Name"} = Commands3.parse_poke_command("poke \"Character Name\"")
      assert {:ok, "Another Name"} = Commands3.parse_poke_command("poke 'Another Name'")
    end

    test "parses poke command with single word character name" do
      assert {:ok, "CharacterName"} = Commands3.parse_poke_command("poke CharacterName")
      assert {:ok, "TestChar"} = Commands3.parse_poke_command("poke TestChar")
    end

    test "handles case insensitive poke command" do
      assert {:ok, "CharacterName"} = Commands3.parse_poke_command("POKE CharacterName")
      assert {:ok, "CharacterName"} = Commands3.parse_poke_command("Poke CharacterName")
    end

    test "returns error for invalid poke command format" do
      assert :error = Commands3.parse_poke_command("poke")
      assert :error = Commands3.parse_poke_command("poke ")
      assert :error = Commands3.parse_poke_command("invalid command")
      assert :error = Commands3.parse_poke_command("poke \"unclosed quote")
    end

    test "handles extra whitespace" do
      assert {:ok, "CharacterName"} = Commands3.parse_poke_command("  poke   CharacterName  ")
      assert {:ok, "Character Name"} = Commands3.parse_poke_command("poke  \"Character Name\"  ")
    end
  end

  describe "execute_poke_command/2" do
    setup do
      game_state = %{
        character: %{
          id: 1,
          name: "TestCharacter"
        }
      }

      {:ok, game_state: game_state}
    end

    test "prevents poking yourself", %{game_state: game_state} do
      {response, _updated_state} = Commands3.execute_poke_command(game_state, "TestCharacter")

      assert response == ["You cannot poke yourself!"]
    end

    test "prevents poking yourself case insensitive", %{game_state: game_state} do
      {response, _updated_state} = Commands3.execute_poke_command(game_state, "testcharacter")

      assert response == ["You cannot poke yourself!"]
    end

    test "handles non-existent character", %{game_state: game_state} do
      {response, _updated_state} = Commands3.execute_poke_command(game_state, "NonExistentCharacter")

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "No character named"))
      assert Enum.any?(response, &String.contains?(&1, "NonExistentCharacter"))
      assert Enum.any?(response, &String.contains?(&1, "currently online"))
    end
  end

  describe "handle_poke_notification/2" do
    test "adds poke notification to terminal output" do
      terminal_state = %{
        output: ["Previous message"]
      }

      updated_state = Commands3.handle_poke_notification(terminal_state, "PokerCharacter")

      assert updated_state.output == ["Previous message", "PokerCharacter pokes you!", ""]
    end

    test "handles empty output" do
      terminal_state = %{
        output: []
      }

      updated_state = Commands3.handle_poke_notification(terminal_state, "PokerCharacter")

      assert updated_state.output == ["PokerCharacter pokes you!", ""]
    end
  end

  describe "subscription functions" do
    test "subscribe_to_character_notifications/1 accepts character_id" do
      # This function calls PubSub.subscribe, which we can't easily test without mocking
      # But we can at least verify it doesn't crash
      assert :ok = Commands3.subscribe_to_character_notifications(1)
    end

    test "unsubscribe_from_character_notifications/1 accepts character_id" do
      # This function calls PubSub.unsubscribe, which we can't easily test without mocking
      # But we can at least verify it doesn't crash
      assert :ok = Commands3.unsubscribe_from_character_notifications(1)
    end

    test "unsubscribe_from_player_notifications/1 accepts character_name" do
      # This function calls PubSub.unsubscribe, which we can't easily test without mocking
      # But we can at least verify it doesn't crash
      assert :ok = Commands3.unsubscribe_from_player_notifications("TestCharacter")
    end
  end
end
