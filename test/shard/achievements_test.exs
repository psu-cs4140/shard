defmodule Shard.AchievementsTest do
  use Shard.DataCase

  alias Shard.Achievements
  alias Shard.Achievements.Achievement

  import Shard.AchievementsFixtures

  describe "achievements" do
    test "list_achievements/0 returns all achievements" do
      achievement = achievement_fixture()
      achievements = Achievements.list_achievements()
      assert achievement in achievements
      assert length(achievements) >= 1
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

      assert {:ok, %Achievement{} = achievement} =
               Achievements.update_achievement(achievement, update_attrs)

      assert achievement.name == "Updated Achievement"
      assert achievement.description == "Updated description"
      assert achievement.points == 200
    end

    test "update_achievement/2 with invalid data returns error changeset" do
      achievement = achievement_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Achievements.update_achievement(achievement, %{name: nil})

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

    test "get_achievement!/1 raises when achievement not found" do
      assert_raise Ecto.NoResultsError, fn -> Achievements.get_achievement!(999) end
    end

    test "create_achievement/1 validates required fields" do
      {:error, changeset} = Achievements.create_achievement(%{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_achievement/1 validates points is positive" do
      attrs = valid_achievement_attributes(%{points: -10})
      {:error, changeset} = Achievements.create_achievement(attrs)
      assert %{points: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "list_achievements_by_category/1 filters by category" do
      general_achievement = achievement_fixture(%{category: "general"})
      combat_achievement = achievement_fixture(%{category: "combat"})

      general_achievements = Achievements.list_achievements_by_category("general")
      assert general_achievement in general_achievements
      refute combat_achievement in general_achievements
    end

    test "list_visible_achievements/0 excludes hidden achievements" do
      visible_achievement = achievement_fixture(%{hidden: false})
      hidden_achievement = achievement_fixture(%{hidden: true})

      visible_achievements = Achievements.list_visible_achievements()
      assert visible_achievement in visible_achievements
      refute hidden_achievement in visible_achievements
    end
  end

  describe "achievement changeset validations" do
    test "validates name uniqueness" do
      achievement_fixture(%{name: "Unique Achievement"})

      {:error, changeset} =
        Achievements.create_achievement(%{
          name: "Unique Achievement",
          description: "Another description",
          category: "general",
          points: 50
        })

      assert %{name: ["has already been taken"]} = errors_on(changeset)
    end

    test "accepts valid categories" do
      valid_categories = ["general", "combat", "exploration", "crafting", "social"]

      for category <- valid_categories do
        attrs = valid_achievement_attributes(%{category: category})

        changeset =
          Shard.Achievements.Achievement.changeset(%Shard.Achievements.Achievement{}, attrs)

        assert changeset.valid?, "Expected #{category} to be valid"
      end
    end
  end
end
