defmodule Shard.AchievementsTest do
  use Shard.DataCase

  alias Shard.Achievements
  alias Shard.Achievements.{Achievement, UserAchievement}

  import Shard.AchievementsFixtures
  import Shard.UsersFixtures

  describe "achievements" do
    test "list_achievements/0 returns all achievements" do
      achievement = achievement_fixture()
      assert Achievements.list_achievements() == [achievement]
    end

    test "get_achievement!/1 returns the achievement with given id" do
      achievement = achievement_fixture()
      assert Achievements.get_achievement!(achievement.id) == achievement
    end

    test "get_achievement/1 returns the achievement with given id" do
      achievement = achievement_fixture()
      assert Achievements.get_achievement(achievement.id) == achievement
    end

    test "get_achievement/1 returns nil for non-existent id" do
      assert Achievements.get_achievement(999) == nil
    end

    test "create_achievement/1 with valid data creates an achievement" do
      valid_attrs = valid_achievement_attributes()

      assert {:ok, %Achievement{} = achievement} = Achievements.create_achievement(valid_attrs)
      assert achievement.name == valid_attrs.name
      assert achievement.description == valid_attrs.description
      assert achievement.category == valid_attrs.category
      assert achievement.points == valid_attrs.points
      assert achievement.requirements == valid_attrs.requirements
      assert achievement.is_hidden == valid_attrs.is_hidden
      assert achievement.is_repeatable == valid_attrs.is_repeatable
    end

    test "create_achievement/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Achievements.create_achievement(%{})
    end

    test "update_achievement/2 with valid data updates the achievement" do
      achievement = achievement_fixture()
      update_attrs = %{
        name: "Updated Achievement",
        description: "Updated description",
        points: 200
      }

      assert {:ok, %Achievement{} = achievement} = Achievements.update_achievement(achievement, update_attrs)
      assert achievement.name == "Updated Achievement"
      assert achievement.description == "Updated description"
      assert achievement.points == 200
    end

    test "update_achievement/2 with invalid data returns error changeset" do
      achievement = achievement_fixture()
      assert {:error, %Ecto.Changeset{}} = Achievements.update_achievement(achievement, %{name: nil})
      assert achievement == Achievements.get_achievement!(achievement.id)
    end

    test "delete_achievement/1 deletes the achievement" do
      achievement = achievement_fixture()
      assert {:ok, %Achievement{}} = Achievements.delete_achievement(achievement)
      assert_raise Ecto.NoResultsError, fn -> Achievements.get_achievement!(achievement.id) end
    end

    test "change_achievement/1 returns an achievement changeset" do
      achievement = achievement_fixture()
      assert %Ecto.Changeset{} = Achievements.change_achievement(achievement)
    end
  end

  describe "user_achievements" do
    test "list_user_achievements/0 returns all user achievements" do
      user_achievement = user_achievement_fixture()
      assert Achievements.list_user_achievements() == [user_achievement]
    end

    test "get_user_achievement!/1 returns the user achievement with given id" do
      user_achievement = user_achievement_fixture()
      assert Achievements.get_user_achievement!(user_achievement.id) == user_achievement
    end

    test "get_user_achievement/1 returns the user achievement with given id" do
      user_achievement = user_achievement_fixture()
      assert Achievements.get_user_achievement(user_achievement.id) == user_achievement
    end

    test "get_user_achievement/1 returns nil for non-existent id" do
      assert Achievements.get_user_achievement(999) == nil
    end

    test "create_user_achievement/1 with valid data creates a user achievement" do
      valid_attrs = valid_user_achievement_attributes()

      assert {:ok, %UserAchievement{} = user_achievement} = Achievements.create_user_achievement(valid_attrs)
      assert user_achievement.user_id == valid_attrs.user_id
      assert user_achievement.achievement_id == valid_attrs.achievement_id
      assert user_achievement.progress == valid_attrs.progress
    end

    test "create_user_achievement/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Achievements.create_user_achievement(%{})
    end

    test "update_user_achievement/2 with valid data updates the user achievement" do
      user_achievement = user_achievement_fixture()
      update_attrs = %{
        progress: %{"current" => 5, "required" => 10}
      }

      assert {:ok, %UserAchievement{} = user_achievement} = 
        Achievements.update_user_achievement(user_achievement, update_attrs)
      assert user_achievement.progress == update_attrs.progress
    end

    test "update_user_achievement/2 with invalid data returns error changeset" do
      user_achievement = user_achievement_fixture()
      assert {:error, %Ecto.Changeset{}} = 
        Achievements.update_user_achievement(user_achievement, %{user_id: nil})
      assert user_achievement == Achievements.get_user_achievement!(user_achievement.id)
    end

    test "delete_user_achievement/1 deletes the user achievement" do
      user_achievement = user_achievement_fixture()
      assert {:ok, %UserAchievement{}} = Achievements.delete_user_achievement(user_achievement)
      assert_raise Ecto.NoResultsError, fn -> Achievements.get_user_achievement!(user_achievement.id) end
    end

    test "change_user_achievement/1 returns a user achievement changeset" do
      user_achievement = user_achievement_fixture()
      assert %Ecto.Changeset{} = Achievements.change_user_achievement(user_achievement)
    end

    test "get_user_achievements_by_user/1 returns achievements for a specific user" do
      user = user_fixture()
      user_achievement = user_achievement_fixture(%{user_id: user.id})
      _other_user_achievement = user_achievement_fixture()

      achievements = Achievements.get_user_achievements_by_user(user.id)
      assert length(achievements) == 1
      assert hd(achievements).id == user_achievement.id
    end

    test "user_has_achievement?/2 returns true when user has achievement" do
      user_achievement = user_achievement_fixture()
      
      assert Achievements.user_has_achievement?(user_achievement.user_id, user_achievement.achievement_id)
    end

    test "user_has_achievement?/2 returns false when user doesn't have achievement" do
      user = user_fixture()
      achievement = achievement_fixture()
      
      refute Achievements.user_has_achievement?(user.id, achievement.id)
    end
  end
end
