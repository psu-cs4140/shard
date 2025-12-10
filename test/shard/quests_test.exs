defmodule Shard.QuestsTest do
  use Shard.DataCase

  alias Shard.Quests
  alias Shard.Quests.{Quest, QuestAcceptance}

  describe "quests" do
    @valid_quest_attrs %{
      title: "Test Quest",
      description: "A test quest for testing",
      level_required: 1,
      experience_reward: 100,
      gold_reward: 50,
      requirements: %{"kill" => %{"goblins" => 5}},
      rewards: %{"items" => []},
      status: "available",
      quest_type: "main",
      difficulty: "easy"
    }

    @invalid_quest_attrs %{
      title: nil,
      description: nil,
      level_required: nil
    }

    def quest_fixture(attrs \\ %{}) do
      {:ok, quest} =
        attrs
        |> Enum.into(@valid_quest_attrs)
        |> Quests.create_quest()

      quest
    end

    test "list_quests/0 returns all quests" do
      quest = quest_fixture()
      quests = Quests.list_quests()
      assert length(quests) >= 1
      assert Enum.any?(quests, fn q -> q.id == quest.id end)
    end

    test "get_quest!/1 returns the quest with given id" do
      quest = quest_fixture()
      assert Quests.get_quest!(quest.id).id == quest.id
    end

    test "get_quest!/1 raises when quest not found" do
      assert_raise Ecto.NoResultsError, fn -> Quests.get_quest!(999) end
    end

    test "create_quest/1 with valid data creates a quest" do
      assert {:ok, %Quest{} = quest} = Quests.create_quest(@valid_quest_attrs)
      assert quest.title == "Test Quest"
      assert quest.description == "A test quest for testing"
      assert quest.level_required == 1
      assert quest.experience_reward == 100
      assert quest.gold_reward == 50
      assert quest.status == "available"
    end

    test "create_quest/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Quests.create_quest(@invalid_quest_attrs)
    end

    test "update_quest/2 with valid data updates the quest" do
      quest = quest_fixture()
      update_attrs = %{title: "Updated Quest", experience_reward: 200}

      assert {:ok, %Quest{} = updated_quest} = Quests.update_quest(quest, update_attrs)
      assert updated_quest.title == "Updated Quest"
      assert updated_quest.experience_reward == 200
    end

    test "update_quest/2 with invalid data returns error changeset" do
      quest = quest_fixture()
      assert {:error, %Ecto.Changeset{}} = Quests.update_quest(quest, @invalid_quest_attrs)

      refreshed_quest = Quests.get_quest!(quest.id)
      assert refreshed_quest.title == quest.title
    end

    test "delete_quest/1 deletes the quest" do
      quest = quest_fixture()
      assert {:ok, %Quest{}} = Quests.delete_quest(quest)
      assert_raise Ecto.NoResultsError, fn -> Quests.get_quest!(quest.id) end
    end

    test "change_quest/1 returns a quest changeset" do
      quest = quest_fixture()
      assert %Ecto.Changeset{} = Quests.change_quest(quest)
    end

    test "get_quests_by_type/1 filters by type" do
      quest = quest_fixture(%{quest_type: "side"})
      quests = Quests.get_quests_by_type("side")
      assert is_list(quests)
      assert Enum.any?(quests, fn q -> q.id == quest.id end)
    end

    test "get_quests_by_difficulty/1 filters by difficulty" do
      quest = quest_fixture(%{difficulty: "hard"})
      quests = Quests.get_quests_by_difficulty("hard")
      assert is_list(quests)
      assert Enum.any?(quests, fn q -> q.id == quest.id end)
    end

    test "get_quests_by_status/1 filters by status" do
      quest = quest_fixture(%{status: "completed"})
      quests = Quests.get_quests_by_status("completed")
      assert is_list(quests)
      assert Enum.any?(quests, fn q -> q.id == quest.id end)
    end

    test "get_available_quests_for_level/1 filters by level" do
      quest = quest_fixture(%{level_required: 5, status: "available"})
      quests = Quests.get_available_quests_for_level(5)
      assert is_list(quests)
      assert Enum.any?(quests, fn q -> q.id == quest.id end)
    end
  end

  describe "quest_acceptances" do
    @valid_acceptance_attrs %{
      user_id: 1,
      quest_id: 1,
      status: "accepted",
      accepted_at: DateTime.utc_now(),
      progress: %{}
    }

    @invalid_acceptance_attrs %{
      user_id: nil,
      quest_id: nil,
      status: nil,
      accepted_at: nil
    }

    def quest_acceptance_fixture(attrs \\ %{}) do
      quest = quest_fixture()
      
      attrs = 
        attrs
        |> Enum.into(@valid_acceptance_attrs)
        |> Map.put(:quest_id, quest.id)

      {:ok, acceptance} = Quests.create_quest_acceptance(attrs)
      acceptance
    end

    test "create_quest_acceptance/1 with valid data creates acceptance" do
      quest = quest_fixture()
      attrs = Map.put(@valid_acceptance_attrs, :quest_id, quest.id)

      assert {:ok, %QuestAcceptance{} = acceptance} = Quests.create_quest_acceptance(attrs)
      assert acceptance.user_id == 1
      assert acceptance.quest_id == quest.id
      assert acceptance.status == "accepted"
    end

    test "create_quest_acceptance/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Quests.create_quest_acceptance(@invalid_acceptance_attrs)
    end

    test "get_user_quest_progress/2 returns quest progress" do
      acceptance = quest_acceptance_fixture()
      
      progress = Quests.get_user_quest_progress(acceptance.user_id, acceptance.quest_id)
      assert progress.id == acceptance.id
    end

    test "get_user_quest_progress/2 returns nil for non-existent progress" do
      progress = Quests.get_user_quest_progress(999, 999)
      assert is_nil(progress)
    end

    test "quest_accepted_by_user?/2 returns boolean" do
      acceptance = quest_acceptance_fixture()
      
      assert Quests.quest_accepted_by_user?(acceptance.user_id, acceptance.quest_id)
      refute Quests.quest_accepted_by_user?(999, 999)
    end

    test "quest_in_progress_by_user?/2 returns boolean" do
      acceptance = quest_acceptance_fixture(%{status: "in_progress"})
      
      assert Quests.quest_in_progress_by_user?(acceptance.user_id, acceptance.quest_id)
      refute Quests.quest_in_progress_by_user?(999, 999)
    end

    test "quest_completed_by_user?/2 returns boolean" do
      acceptance = quest_acceptance_fixture(%{status: "completed"})
      
      assert Quests.quest_completed_by_user?(acceptance.user_id, acceptance.quest_id)
      refute Quests.quest_completed_by_user?(999, 999)
    end

    test "quest_ever_accepted_by_user?/2 returns boolean" do
      acceptance = quest_acceptance_fixture()
      
      assert Quests.quest_ever_accepted_by_user?(acceptance.user_id, acceptance.quest_id)
      refute Quests.quest_ever_accepted_by_user?(999, 999)
    end

    test "get_user_quest_acceptances/1 returns list" do
      acceptance = quest_acceptance_fixture()
      
      acceptances = Quests.get_user_quest_acceptances(acceptance.user_id)
      assert is_list(acceptances)
      assert Enum.any?(acceptances, fn a -> a.id == acceptance.id end)
    end

    test "get_user_active_quests/1 returns list" do
      acceptance = quest_acceptance_fixture(%{status: "in_progress"})
      
      quests = Quests.get_user_active_quests(acceptance.user_id)
      assert is_list(quests)
      assert Enum.any?(quests, fn q -> q.id == acceptance.quest_id end)
    end

    test "get_available_quests_for_user/1 returns list" do
      user_id = 1
      quests = Quests.get_available_quests_for_user(user_id)
      assert is_list(quests)
    end

    test "get_available_quests_by_giver/2 returns list" do
      quest = quest_fixture(%{quest_giver_id: 1})
      
      quests = Quests.get_available_quests_by_giver(1, 1)
      assert is_list(quests)
    end

    test "get_available_quests_by_giver_excluding_completed/2 returns list" do
      quest = quest_fixture(%{quest_giver_id: 1})
      
      quests = Quests.get_available_quests_by_giver_excluding_completed(1, 1)
      assert is_list(quests)
    end
  end

  describe "QuestAcceptance changeset" do
    test "validates required fields" do
      changeset = QuestAcceptance.changeset(%QuestAcceptance{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.user_id
      assert "can't be blank" in errors.quest_id
      assert "can't be blank" in errors.status
      assert "can't be blank" in errors.accepted_at
    end

    test "validates status inclusion" do
      attrs = %{
        user_id: 1,
        quest_id: 1,
        status: "invalid_status",
        accepted_at: DateTime.utc_now()
      }

      changeset = QuestAcceptance.changeset(%QuestAcceptance{}, attrs)
      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid status values" do
      valid_statuses = ["accepted", "in_progress", "completed", "failed", "abandoned"]

      for status <- valid_statuses do
        attrs = %{
          user_id: 1,
          quest_id: 1,
          status: status,
          accepted_at: DateTime.utc_now()
        }

        changeset = QuestAcceptance.changeset(%QuestAcceptance{}, attrs)
        assert changeset.valid?
      end
    end
  end

  describe "QuestAcceptance.accept_changeset/2" do
    test "validates required fields" do
      changeset = QuestAcceptance.accept_changeset(%QuestAcceptance{}, %{})
      refute changeset.valid?

      assert %{user_id: ["can't be blank"], quest_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "sets default values" do
      attrs = %{user_id: 1, quest_id: 1}
      changeset = QuestAcceptance.accept_changeset(%QuestAcceptance{}, attrs)
      
      assert changeset.valid?
      assert get_change(changeset, :status) == "accepted"
      assert get_change(changeset, :progress) == %{}
    end
  end

  describe "Quest changeset" do
    test "validates required fields" do
      changeset = Quest.changeset(%Quest{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.title
      assert "can't be blank" in errors.description
      assert "can't be blank" in errors.level_required
    end

    test "validates numeric fields are non-negative" do
      attrs = %{
        title: "Test Quest",
        description: "Test description",
        level_required: -1,
        experience_reward: -1,
        gold_reward: -1
      }

      changeset = Quest.changeset(%Quest{}, attrs)
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "must be greater than 0" in errors.level_required
      assert "must be greater than or equal to 0" in errors.experience_reward
      assert "must be greater than or equal to 0" in errors.gold_reward
    end

    test "validates status inclusion" do
      attrs = %{
        title: "Test Quest",
        description: "Test description",
        level_required: 1,
        status: "invalid_status"
      }

      changeset = Quest.changeset(%Quest{}, attrs)
      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid quest data" do
      changeset = Quest.changeset(%Quest{}, @valid_quest_attrs)
      assert changeset.valid?
    end
  end
end
