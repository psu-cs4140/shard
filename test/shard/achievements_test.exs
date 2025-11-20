defmodule Shard.AchievementsTest do
  use Shard.DataCase

  alias Shard.Achievements
  alias Shard.Achievements.Achievement

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


    test "create_achievement/1 with valid data creates an achievement" do
      valid_attrs = valid_achievement_attributes()

      assert {:ok, %Achievement{} = achievement} = Achievements.create_achievement(valid_attrs)
      assert achievement.name == valid_attrs.name
      assert achievement.description == valid_attrs.description
      assert achievement.category == valid_attrs.category
      assert achievement.points == valid_attrs.points
      assert achievement.requirements == valid_attrs.requirements
      assert achievement.hidden == valid_attrs.hidden
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

end
