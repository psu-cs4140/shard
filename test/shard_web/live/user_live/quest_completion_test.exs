defmodule ShardWeb.UserLive.QuestCompletionTest do
  use Shard.DataCase

  alias ShardWeb.UserLive.QuestHandlers
  alias Shard.{Quests, Characters, Npcs}

  import Shard.UsersFixtures

  describe "find_deliverable_quest/2" do
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
          name: "Quest Turn In",
          description: "An NPC for turning in quests",
          level: 5,
          health: 100,
          max_health: 100
        })

      {:ok, quest} =
        Quests.create_quest(%{
          title: "Deliverable Quest",
          description: "A quest that can be turned in",
          short_description: "Deliverable quest",
          quest_type: "repeatable",
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

    test "returns nil when no quests in progress", %{npc: npc} do
      player_quests = []

      result = QuestHandlers.find_deliverable_quest(player_quests, npc)

      assert result == nil
    end

    test "returns nil when quest is not in progress", %{npc: npc, quest: quest} do
      player_quests = [
        %{id: quest.id, status: "Completed", title: quest.title}
      ]

      result = QuestHandlers.find_deliverable_quest(player_quests, npc)

      assert result == nil
    end

    test "returns quest when it's in progress and can be turned in to NPC", %{
      npc: npc,
      quest: quest
    } do
      player_quests = [
        %{id: quest.id, status: "In Progress", title: quest.title}
      ]

      result = QuestHandlers.find_deliverable_quest(player_quests, npc)

      assert result != nil
      assert result.id == quest.id
    end

    test "returns nil when quest cannot be turned in to this NPC", %{quest: quest} do
      # Create a different NPC
      {:ok, other_npc} =
        Npcs.create_npc(%{
          name: "Other NPC",
          description: "A different NPC",
          level: 5,
          health: 100,
          max_health: 100
        })

      player_quests = [
        %{id: quest.id, status: "In Progress", title: quest.title}
      ]

      result = QuestHandlers.find_deliverable_quest(player_quests, other_npc)

      assert result == nil
    end
  end

  describe "complete_quest_and_give_rewards/3" do
    setup do
      user = user_fixture()

      {:ok, character} =
        Characters.create_character(%{
          name: "Test Character",
          class: "warrior",
          race: "human",
          user_id: user.id,
          experience: 0,
          gold: 0,
          level: 1
        })

      {:ok, npc} =
        Npcs.create_npc(%{
          name: "Quest Turn In",
          description: "An NPC for turning in quests",
          level: 5,
          health: 100,
          max_health: 100
        })

      {:ok, quest} =
        Quests.create_quest(%{
          title: "Completable Quest",
          description: "A quest that can be completed",
          short_description: "Completable quest",
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

      # Accept the quest first
      {:ok, _} = Quests.accept_quest(user.id, quest.id)

      player_quest = %{
        id: quest.id,
        title: quest.title,
        status: "In Progress",
        progress: "0% complete"
      }

      game_state = %{
        character: character,
        quests: [player_quest],
        player_stats: %{
          experience: 0,
          gold: 0,
          level: 1,
          next_level_exp: 1000
        }
      }

      %{
        character: character,
        npc: npc,
        quest: quest,
        player_quest: player_quest,
        game_state: game_state
      }
    end

    test "successfully completes quest and gives rewards", %{
      game_state: game_state,
      player_quest: player_quest,
      npc: npc
    } do
      {response, updated_state} =
        QuestHandlers.complete_quest_and_give_rewards(game_state, player_quest, npc)

      assert is_list(response)
      assert Enum.any?(response, &String.contains?(&1, "completed the quest"))
      assert Enum.any?(response, &String.contains?(&1, "Experience gained"))

      # Check that quest status is updated
      completed_quest = Enum.find(updated_state.quests, &(&1.id == player_quest.id))
      assert completed_quest.status == "Completed"
    end

    test "handles database errors gracefully", %{game_state: game_state, npc: npc} do
      # Use a quest that doesn't exist in the database
      fake_quest = %{
        id: 99999,
        title: "Fake Quest",
        status: "In Progress",
        progress: "0% complete"
      }

      # Add the fake quest to the game state so it can be found and updated
      game_state_with_fake = %{game_state | quests: [fake_quest]}

      {response, updated_state} =
        QuestHandlers.complete_quest_and_give_rewards(game_state_with_fake, fake_quest, npc)

      assert is_list(response)
      # Should still mark quest as completed in local state even if database fails
      completed_quest = Enum.find(updated_state.quests, &(&1.id == fake_quest.id))
      assert completed_quest != nil
      assert completed_quest.status == "Completed"
    end
  end

  describe "check_level_up/1" do
    test "returns updated stats and message when leveling up" do
      stats = %{
        experience: 1000,
        level: 1,
        next_level_exp: 1000,
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        constitution: 10,
        health: 100,
        max_health: 100,
        max_stamina: 120,
        max_mana: 80
      }

      {updated_stats, message} = QuestHandlers.check_level_up(stats)

      assert updated_stats.level == 2
      # 1000 + (2 * 500)
      assert updated_stats.next_level_exp == 2000
      assert updated_stats.strength == 11
      assert updated_stats.dexterity == 11
      assert updated_stats.intelligence == 11
      assert updated_stats.constitution == 11
      # 100 + (11-10) * 5
      assert updated_stats.max_health == 105
      assert message == "*** LEVEL UP! *** You are now level 2!"
    end

    test "returns unchanged stats when not enough experience" do
      stats = %{
        experience: 500,
        level: 1,
        next_level_exp: 1000,
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        constitution: 10
      }

      {updated_stats, message} = QuestHandlers.check_level_up(stats)

      assert updated_stats == stats
      assert message == nil
    end

    test "handles multiple level ups correctly" do
      stats = %{
        experience: 3000,
        level: 1,
        next_level_exp: 1000,
        strength: 10,
        dexterity: 10,
        intelligence: 10,
        constitution: 10,
        health: 100,
        max_health: 100,
        max_stamina: 120,
        max_mana: 80
      }

      # Should level up to level 2 first
      {updated_stats, message} = QuestHandlers.check_level_up(stats)

      assert updated_stats.level == 2
      assert message == "*** LEVEL UP! *** You are now level 2!"

      # Check if can level up again - with 3000 exp and next level at 2000, should level up again
      {final_stats, second_message} = QuestHandlers.check_level_up(updated_stats)

      # With 3000 exp and next level exp at 2000, should level up to 3
      assert final_stats.level == 3
      assert second_message == "*** LEVEL UP! *** You are now level 3!"
    end
  end

  describe "helper functions" do
    test "quest entry structure is correct when quest is accepted" do
      # Since create_new_quest_entry is private, we test it indirectly through quest acceptance
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
          name: "Test NPC",
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

      game_state = %{
        character: character,
        quests: [],
        pending_quest_offer: %{quest: quest, npc: npc}
      }

      {_response, updated_state} = QuestHandlers.execute_accept_quest(game_state)

      # Check that the quest entry has the correct structure
      quest_entry = hd(updated_state.quests)
      assert quest_entry.id == quest.id
      assert quest_entry.title == "Test Quest"
      assert quest_entry.status == "In Progress"
      assert quest_entry.progress == "0% complete"
      assert quest_entry.npc_giver == "Test NPC"
      assert quest_entry.description == "A test quest"
    end
  end

  describe "error handling" do
    test "handles database connection issues" do
      # This would require mocking the database, but we can test the fallback behavior
      game_state = %{
        # Non-existent IDs
        character: %{user_id: 999_999, id: 999_999},
        quests: [],
        player_stats: %{experience: 0, gold: 0, level: 1}
      }

      fake_quest = %{id: 999_999, title: "Fake Quest", status: "In Progress"}
      fake_npc = %{id: 999_999, name: "Fake NPC"}

      {response, updated_state} =
        QuestHandlers.complete_quest_and_give_rewards(game_state, fake_quest, fake_npc)

      # Should handle gracefully and still update local state
      assert is_list(response)
      assert is_map(updated_state)
    end
  end
end
