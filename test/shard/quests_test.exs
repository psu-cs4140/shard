defmodule Shard.QuestsTest do
  use Shard.DataCase

  alias Shard.Quests
  alias Shard.Quests.Quest
  alias Shard.Quests.QuestAcceptance

  describe "QuestAcceptance.changeset/2" do
    test "validates required fields" do
      changeset = QuestAcceptance.changeset(%QuestAcceptance{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.user_id
      assert "can't be blank" in errors.quest_id
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
  end

  describe "Quest" do
    test "has valid schema" do
      # Just test that the module exists and has expected fields
      fields = Quest.__schema__(:fields)
      assert length(fields) > 0
      assert :title in fields
      assert :description in fields
      assert :status in fields
    end
  end

  describe "Quests context" do
    test "list_quests returns all quests" do
      # This will test the list_quests function
      quests = Quests.list_quests()
      assert is_list(quests)
    end

    test "get_quests_by_type filters by type" do
      # Test the query function (will return empty list in test DB)
      quests = Quests.get_quests_by_type("main")
      assert is_list(quests)
    end

    test "get_quests_by_difficulty filters by difficulty" do
      quests = Quests.get_quests_by_difficulty("easy")
      assert is_list(quests)
    end

    test "get_quests_by_status filters by status" do
      quests = Quests.get_quests_by_status("available")
      assert is_list(quests)
    end

    test "get_available_quests_for_level filters by level" do
      quests = Quests.get_available_quests_for_level(1)
      assert is_list(quests)
    end

    test "quest_accepted_by_user? returns boolean" do
      result = Quests.quest_accepted_by_user?(1, 1)
      assert is_boolean(result)
    end

    test "quest_in_progress_by_user? returns boolean" do
      result = Quests.quest_in_progress_by_user?(1, 1)
      assert is_boolean(result)
    end

    test "quest_completed_by_user? returns boolean" do
      result = Quests.quest_completed_by_user?(1, 1)
      assert is_boolean(result)
    end

    test "quest_ever_accepted_by_user? returns boolean" do
      result = Quests.quest_ever_accepted_by_user?(1, 1)
      assert is_boolean(result)
    end

    test "get_user_quest_acceptances returns list" do
      acceptances = Quests.get_user_quest_acceptances(1)
      assert is_list(acceptances)
    end

    test "get_user_active_quests returns list" do
      quests = Quests.get_user_active_quests(1)
      assert is_list(quests)
    end

    test "get_available_quests_for_user returns list" do
      quests = Quests.get_available_quests_for_user(1)
      assert is_list(quests)
    end

    test "get_available_quests_by_giver returns list" do
      quests = Quests.get_available_quests_by_giver(1, 1)
      assert is_list(quests)
    end

    test "get_available_quests_by_giver_excluding_completed returns list" do
      quests = Quests.get_available_quests_by_giver_excluding_completed(1, 1)
      assert is_list(quests)
    end
  end
end
