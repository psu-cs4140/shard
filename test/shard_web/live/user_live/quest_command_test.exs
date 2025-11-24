defmodule ShardWeb.UserLive.QuestCommandTest do
  use Shard.DataCase

  alias ShardWeb.UserLive.QuestHandlers
  alias Shard.{Quests, Characters, Npcs, Map}

  import Shard.UsersFixtures

  describe "execute_quest_command/2" do
    setup do
      user = user_fixture()

      {:ok, zone} =
        Map.create_zone(%{
          name: "Test Zone",
          slug: "test-zone",
          description: "A test zone",
          zone_type: "dungeon",
          min_level: 1,
          max_level: 10,
          is_public: true
        })

      {:ok, room} =
        Map.create_room(%{
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          zone_id: zone.id,
          is_public: true,
          room_type: "standard"
        })

      {:ok, character} =
        Characters.create_character(%{
          name: "Test Character",
          class: "warrior",
          race: "human",
          user_id: user.id,
          current_zone_id: zone.id
        })

      {:ok, npc} =
        Npcs.create_npc(%{
          name: "Quest Giver",
          description: "A helpful NPC",
          level: 5,
          health: 100,
          max_health: 100,
          room_id: room.id
        })

      {:ok, quest} =
        Quests.create_quest(%{
          title: "Test Quest",
          description: "A test quest",
          short_description: "Test quest",
          quest_type: "main",
          difficulty: "easy",
          min_level: 1,
          max_level: 10,
          experience_reward: 100,
          gold_reward: 50,
          giver_npc_id: npc.id,
          turn_in_npc_id: npc.id,
          objectives: %{"kill" => %{"monster_type" => "orc", "count" => 5}},
          requirements: %{},
          rewards: %{}
        })

      game_state = %{
        character: character,
        player_position: {0, 0},
        quests: [],
        pending_quest_offer: nil
      }

      %{
        user: user,
        character: character,
        npc: npc,
        quest: quest,
        game_state: game_state,
        room: room,
        zone: zone
      }
    end

    test "returns error when NPC not found", %{game_state: game_state} do
      {response, updated_state} =
        QuestHandlers.execute_quest_command(game_state, "Nonexistent NPC")

      assert response == ["There is no NPC named 'Nonexistent NPC' here."]
      assert updated_state == game_state
    end

    test "presents quest offer when NPC has available quest", %{
      game_state: game_state,
      npc: npc,
      quest: quest,
      room: room
    } do
      # Update the NPC to have location coordinates that match the room
      {:ok, updated_npc} =
        Npcs.update_npc(npc, %{
          location_x: room.x_coordinate,
          location_y: room.y_coordinate,
          location_z: room.z_coordinate
        })

      # Update character to be in the same zone as the NPC
      updated_character = %{game_state.character | current_zone_id: room.zone_id}

      game_state = %{
        game_state
        | character: updated_character,
          player_position: {room.x_coordinate, room.y_coordinate}
      }

      {response, updated_state} =
        QuestHandlers.execute_quest_command(game_state, updated_npc.name)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, quest.title))
      assert updated_state.pending_quest_offer != nil
      assert updated_state.pending_quest_offer.quest.id == quest.id
      assert updated_state.pending_quest_offer.npc.id == updated_npc.id
    end

    test "returns no quests message when NPC has no available quests", %{
      game_state: game_state,
      npc: npc,
      quest: quest,
      room: room
    } do
      # Accept the quest first to make it unavailable
      {:ok, _} = Quests.accept_quest(game_state.character.user_id, quest.id)

      # Update the NPC to have location coordinates that match the room
      {:ok, updated_npc} =
        Npcs.update_npc(npc, %{
          location_x: room.x_coordinate,
          location_y: room.y_coordinate,
          location_z: room.z_coordinate
        })

      # Update character to be in the same zone as the NPC
      updated_character = %{game_state.character | current_zone_id: room.zone_id}

      game_state = %{
        game_state
        | character: updated_character,
          player_position: {room.x_coordinate, room.y_coordinate}
      }

      {response, updated_state} =
        QuestHandlers.execute_quest_command(game_state, updated_npc.name)

      assert response == ["#{updated_npc.name} has no quests available for you at this time."]
      assert updated_state == game_state
    end
  end

  describe "execute_accept_quest/1" do
    setup do
      user = user_fixture()

      {:ok, character} =
        Characters.create_character(%{
          name: "Test Character",
          class: "warrior",
          race: "human",
          user_id: user.id
        })

      {:ok, npc} =
        Npcs.create_npc(%{
          name: "Quest Giver",
          description: "A helpful NPC",
          level: 5,
          health: 100,
          max_health: 100
        })

      {:ok, quest} =
        Quests.create_quest(%{
          title: "Test Quest",
          description: "A test quest",
          short_description: "Test quest",
          quest_type: "side",
          difficulty: "easy",
          min_level: 1,
          max_level: 10,
          experience_reward: 100,
          gold_reward: 50,
          giver_npc_id: npc.id,
          turn_in_npc_id: npc.id,
          objectives: %{"kill" => %{"monster_type" => "orc", "count" => 5}},
          requirements: %{},
          rewards: %{}
        })

      %{
        user: user,
        character: character,
        npc: npc,
        quest: quest
      }
    end

    test "returns error when no quest offer pending" do
      game_state = %{
        character: %{user_id: 1},
        quests: [],
        pending_quest_offer: nil
      }

      {response, updated_state} = QuestHandlers.execute_accept_quest(game_state)

      assert response == ["There is no quest offer to accept."]
      assert updated_state == game_state
    end

    test "successfully accepts quest when valid offer exists", %{
      character: character,
      npc: npc,
      quest: quest
    } do
      game_state = %{
        character: character,
        quests: [],
        pending_quest_offer: %{quest: quest, npc: npc}
      }

      {response, updated_state} = QuestHandlers.execute_accept_quest(game_state)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "accept the quest"))
      assert updated_state.pending_quest_offer == nil
      assert length(updated_state.quests) == 1

      quest_in_state = hd(updated_state.quests)
      assert quest_in_state.id == quest.id
      assert quest_in_state.status == "In Progress"
    end

    test "handles already accepted quest", %{character: character, npc: npc, quest: quest} do
      # Accept the quest first
      {:ok, _} = Quests.accept_quest(character.user_id, quest.id)

      game_state = %{
        character: character,
        quests: [],
        pending_quest_offer: %{quest: quest, npc: npc}
      }

      {response, updated_state} = QuestHandlers.execute_accept_quest(game_state)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "already accepted"))
      assert updated_state.pending_quest_offer == nil
    end
  end

  describe "execute_deny_quest/1" do
    setup do
      user = user_fixture()

      {:ok, character} =
        Characters.create_character(%{
          name: "Test Character",
          class: "warrior",
          race: "human",
          user_id: user.id
        })

      {:ok, npc} =
        Npcs.create_npc(%{
          name: "Quest Giver",
          description: "A helpful NPC",
          level: 5,
          health: 100,
          max_health: 100
        })

      {:ok, quest} =
        Quests.create_quest(%{
          title: "Test Quest",
          description: "A test quest",
          short_description: "Test quest",
          quest_type: "daily",
          difficulty: "easy",
          min_level: 1,
          max_level: 10,
          experience_reward: 100,
          gold_reward: 50,
          giver_npc_id: npc.id,
          turn_in_npc_id: npc.id,
          objectives: %{"kill" => %{"monster_type" => "orc", "count" => 5}},
          requirements: %{},
          rewards: %{}
        })

      %{
        character: character,
        npc: npc,
        quest: quest
      }
    end

    test "returns error when no quest offer pending" do
      game_state = %{
        character: %{user_id: 1},
        quests: [],
        pending_quest_offer: nil
      }

      {response, updated_state} = QuestHandlers.execute_deny_quest(game_state)

      assert response == ["There is no quest offer to deny."]
      assert updated_state == game_state
    end

    test "successfully denies quest when valid offer exists", %{
      character: character,
      npc: npc,
      quest: quest
    } do
      game_state = %{
        character: character,
        quests: [],
        pending_quest_offer: %{quest: quest, npc: npc}
      }

      {response, updated_state} = QuestHandlers.execute_deny_quest(game_state)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "decline the quest"))
      assert updated_state.pending_quest_offer == nil
      assert updated_state.quests == []
    end
  end

  describe "error handling" do
    test "handles missing quest data gracefully" do
      game_state = %{
        character: %{user_id: 1, id: 1, current_zone_id: 1},
        quests: [],
        player_stats: %{experience: 0, gold: 0, level: 1},
        pending_quest_offer: nil,
        player_position: {0, 0}
      }

      # Test with nil NPC
      {response, _} = QuestHandlers.execute_quest_command(game_state, "Missing NPC")
      assert is_list(response)
      assert hd(response) =~ "no NPC named"
    end
  end
end
