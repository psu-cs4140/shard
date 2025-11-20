defmodule Shard.Achievements.AchievementTest do
  use Shard.DataCase

  alias Shard.Achievements.Achievement

  import Shard.AchievementsFixtures

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = valid_achievement_attributes()
      changeset = Achievement.changeset(%Achievement{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset when name is missing" do
      attrs = valid_achievement_attributes(%{name: nil})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "invalid changeset when description is missing" do
      attrs = valid_achievement_attributes(%{description: nil})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).description
    end

    test "invalid changeset when category is missing" do
      attrs = valid_achievement_attributes(%{category: nil})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).category
    end

    test "invalid changeset when points is negative" do
      attrs = valid_achievement_attributes(%{points: -1})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).points
    end

    test "valid changeset when points is zero" do
      attrs = valid_achievement_attributes(%{points: 0})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset when requirements is empty map" do
      attrs = valid_achievement_attributes(%{requirements: %{}})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset when requirements is nil" do
      attrs = valid_achievement_attributes(%{requirements: nil})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset with boolean flags" do
      attrs = valid_achievement_attributes(%{is_hidden: true, is_repeatable: true})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      assert changeset.valid?
      assert Ecto.Changeset.get_field(changeset, :is_hidden) == true
      assert Ecto.Changeset.get_field(changeset, :is_repeatable) == true
    end

    test "name must be unique" do
      achievement_fixture(%{name: "Unique Achievement"})
      
      attrs = valid_achievement_attributes(%{name: "Unique Achievement"})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      
      assert {:error, changeset} = Repo.insert(changeset)
      assert "has already been taken" in errors_on(changeset).name
    end

    test "name length validation" do
      # Test minimum length
      attrs = valid_achievement_attributes(%{name: "A"})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "should be at least 2 character(s)" in errors_on(changeset).name

      # Test maximum length
      long_name = String.duplicate("A", 256)
      attrs = valid_achievement_attributes(%{name: long_name})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).name
    end

    test "description length validation" do
      # Test minimum length
      attrs = valid_achievement_attributes(%{description: "A"})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "should be at least 10 character(s)" in errors_on(changeset).description

      # Test maximum length
      long_description = String.duplicate("A", 1001)
      attrs = valid_achievement_attributes(%{description: long_description})
      changeset = Achievement.changeset(%Achievement{}, attrs)
      refute changeset.valid?
      assert "should be at most 1000 character(s)" in errors_on(changeset).description
    end
  end
end
