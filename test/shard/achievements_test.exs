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

    test "get_achievement!/1 raises when achievement not found" do
      assert_raise Ecto.NoResultsError, fn -> Achievements.get_achievement!(999) end
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

    test "create_achievement/1 validates required fields" do
      {:error, changeset} = Achievements.create_achievement(%{})
      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.description
    end

    test "create_achievement/1 validates points is positive" do
      attrs = valid_achievement_attributes(%{points: -10})
      {:error, changeset} = Achievements.create_achievement(attrs)
      errors = errors_on(changeset)
      assert "must be greater than 0" in errors.points
    end

    test "create_achievement/1 validates category inclusion" do
      attrs = valid_achievement_attributes(%{category: "invalid_category"})
      {:error, changeset} = Achievements.create_achievement(attrs)
      errors = errors_on(changeset)
      assert "is invalid" in errors.category
    end

    test "create_achievement/1 accepts valid categories" do
      valid_categories = ["general", "combat", "exploration", "crafting", "social"]
      
      for category <- valid_categories do
        attrs = valid_achievement_attributes(%{category: category})
        assert {:ok, %Achievement{}} = Achievements.create_achievement(attrs)
      end
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

    test "change_achievement/1 with attributes returns changeset with changes" do
      achievement = achievement_fixture()
      attrs = %{name: "New Name"}
      changeset = Achievements.change_achievement(achievement, attrs)
      assert changeset.changes.name == "New Name"
    end
  end

  describe "Achievement changeset" do
    test "validates name uniqueness" do
      achievement = achievement_fixture(%{name: "Unique Achievement"})
      attrs = valid_achievement_attributes(%{name: "Unique Achievement"})
      
      {:error, changeset} = Achievements.create_achievement(attrs)
      errors = errors_on(changeset)
      assert "has already been taken" in errors.name
    end

    test "validates requirements is a map" do
      attrs = valid_achievement_attributes(%{requirements: "invalid"})
      {:error, changeset} = Achievements.create_achievement(attrs)
      errors = errors_on(changeset)
      assert "is invalid" in errors.requirements
    end

    test "accepts empty requirements map" do
      attrs = valid_achievement_attributes(%{requirements: %{}})
      assert {:ok, %Achievement{}} = Achievements.create_achievement(attrs)
    end

    test "accepts nil requirements" do
      attrs = valid_achievement_attributes(%{requirements: nil})
      assert {:ok, %Achievement{}} = Achievements.create_achievement(attrs)
    end
  end
end
