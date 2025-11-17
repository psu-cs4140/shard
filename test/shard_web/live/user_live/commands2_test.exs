defmodule ShardWeb.UserLive.Commands2Test do
  use Shard.DataCase, async: true
  alias ShardWeb.UserLive.Commands2

  describe "execute_talk_command/2" do
    setup do
      game_state = %{
        player_position: {0, 0},
        map_id: 1,
        character: %{current_zone_id: 1}
      }

      {:ok, game_state: game_state}
    end

    test "talking to non-existent NPC", %{game_state: game_state} do
      {response, _updated_state} = Commands2.execute_talk_command(game_state, "NonExistentNPC")

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "There are no NPCs here"))
    end
  end

  describe "execute_quest_command/2" do
    setup do
      game_state = %{
        player_position: {0, 0},
        map_id: 1,
        character: %{current_zone_id: 1}
      }

      {:ok, game_state: game_state}
    end

    test "asking for quest from non-existent NPC", %{game_state: game_state} do
      {response, _updated_state} = Commands2.execute_quest_command(game_state, "NonExistentNPC")

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "There are no NPCs here"))
    end
  end

  describe "execute_deliver_quest_command/2" do
    setup do
      game_state = %{
        player_position: {0, 0},
        map_id: 1,
        character: %{current_zone_id: 1},
        quests: []
      }

      {:ok, game_state: game_state}
    end

    test "delivering quest to non-existent NPC", %{game_state: game_state} do
      {response, _updated_state} =
        Commands2.execute_deliver_quest_command(game_state, "NonExistentNPC")

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "There are no NPCs here"))
    end
  end

  describe "generate_npc_dialogue/2" do
    test "generates dialogue for NPC with basic info" do
      npc = %{
        id: 1,
        name: "TestNPC",
        dialogue: "Hello, traveler!",
        npc_type: "friendly"
      }

      game_state = %{}

      response = Commands2.generate_npc_dialogue(npc, game_state)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "TestNPC"))
      assert Enum.any?(response, &String.contains?(&1, "Hello, traveler!"))
      assert Enum.any?(response, &String.contains?(&1, "smiles warmly"))
    end

    test "generates dialogue for NPC with nil dialogue" do
      npc = %{
        id: 1,
        name: "SilentNPC",
        dialogue: nil,
        npc_type: "neutral"
      }

      game_state = %{}

      response = Commands2.generate_npc_dialogue(npc, game_state)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "SilentNPC"))
      assert Enum.any?(response, &String.contains?(&1, "don't have much to say"))
    end

    test "generates dialogue for different NPC types" do
      npc_types = ["friendly", "hostile", "neutral", "merchant", "guard"]

      for npc_type <- npc_types do
        npc = %{
          id: 1,
          name: "TestNPC",
          dialogue: "Test dialogue",
          npc_type: npc_type
        }

        response = Commands2.generate_npc_dialogue(npc, %{})
        assert is_list(response)
        assert Enum.any?(response, &String.contains?(&1, "TestNPC"))
      end
    end
  end

  describe "generate_npc_quest_response/2" do
    test "generates response for NPC with no quests" do
      npc = %{
        id: 1,
        name: "QuestlessNPC"
      }

      game_state = %{}

      {response, _updated_state} = Commands2.generate_npc_quest_response(npc, game_state)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "QuestlessNPC"))
      assert Enum.any?(response, &String.contains?(&1, "don't have any quests"))
    end
  end
end
