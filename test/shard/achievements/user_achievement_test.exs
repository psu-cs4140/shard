defmodule Shard.Achievements.UserAchievementTest do
  use Shard.DataCase

  alias Shard.Achievements.UserAchievement

  import Shard.AchievementsFixtures
  import Shard.UsersFixtures

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = valid_user_achievement_attributes()
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset when user_id is missing" do
      attrs = valid_user_achievement_attributes(%{user_id: nil})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "invalid changeset when achievement_id is missing" do
      attrs = valid_user_achievement_attributes(%{achievement_id: nil})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).achievement_id
    end

    test "valid changeset when earned_at is nil" do
      attrs = valid_user_achievement_attributes(%{earned_at: nil})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset when progress is nil" do
      attrs = valid_user_achievement_attributes(%{progress: nil})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset when progress is empty map" do
      attrs = valid_user_achievement_attributes(%{progress: %{}})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      assert changeset.valid?
    end

    test "unique constraint on user_id and achievement_id combination" do
      user = user_fixture()
      achievement = achievement_fixture()
      
      # Create first user achievement
      user_achievement_fixture(%{user_id: user.id, achievement_id: achievement.id})
      
      # Try to create duplicate
      attrs = valid_user_achievement_attributes(%{user_id: user.id, achievement_id: achievement.id})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      
      assert {:error, changeset} = Repo.insert(changeset)
      assert "has already been taken" in errors_on(changeset).user_id
    end

    test "allows same user to have different achievements" do
      user = user_fixture()
      achievement1 = achievement_fixture(%{name: "Achievement 1"})
      achievement2 = achievement_fixture(%{name: "Achievement 2"})
      
      # Create first user achievement
      user_achievement_fixture(%{user_id: user.id, achievement_id: achievement1.id})
      
      # Create second user achievement for same user
      attrs = valid_user_achievement_attributes(%{user_id: user.id, achievement_id: achievement2.id})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      
      assert {:ok, _user_achievement} = Repo.insert(changeset)
    end

    test "allows different users to have same achievement" do
      user1 = user_fixture()
      user2 = user_fixture()
      achievement = achievement_fixture()
      
      # Create first user achievement
      user_achievement_fixture(%{user_id: user1.id, achievement_id: achievement.id})
      
      # Create second user achievement for different user
      attrs = valid_user_achievement_attributes(%{user_id: user2.id, achievement_id: achievement.id})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      
      assert {:ok, _user_achievement} = Repo.insert(changeset)
    end

    test "foreign key constraint on user_id" do
      attrs = valid_user_achievement_attributes(%{user_id: 999999})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      
      assert {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).user_id
    end

    test "foreign key constraint on achievement_id" do
      attrs = valid_user_achievement_attributes(%{achievement_id: 999999})
      changeset = UserAchievement.changeset(%UserAchievement{}, attrs)
      
      assert {:error, changeset} = Repo.insert(changeset)
      assert "does not exist" in errors_on(changeset).achievement_id
    end
  end
end
