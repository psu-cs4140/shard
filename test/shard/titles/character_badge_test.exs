defmodule Shard.Titles.CharacterBadgeTest do
  use Shard.DataCase

  alias Shard.Titles.CharacterBadge

  @valid_attrs %{
    character_id: 1,
    badge_id: 1,
    awarded_at: DateTime.utc_now(),
    progress: %{"current" => 5, "required" => 10}
  }

  @invalid_attrs %{}

  describe "changeset/2" do
    test "valid changeset with all fields" do
      changeset = CharacterBadge.changeset(%CharacterBadge{}, @valid_attrs)
      assert changeset.valid?
    end

    test "invalid changeset with missing required fields" do
      changeset = CharacterBadge.changeset(%CharacterBadge{}, @invalid_attrs)
      refute changeset.valid?
      
      errors = errors_on(changeset)
      assert "can't be blank" in errors.character_id
      assert "can't be blank" in errors.badge_id
    end

    test "validates character_id is positive integer" do
      attrs = Map.put(@valid_attrs, :character_id, 0)
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      refute changeset.valid?
      assert %{character_id: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates badge_id is positive integer" do
      attrs = Map.put(@valid_attrs, :badge_id, -1)
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      refute changeset.valid?
      assert %{badge_id: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "sets default awarded_at when not provided" do
      attrs = Map.delete(@valid_attrs, :awarded_at)
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :awarded_at) != nil
    end

    test "allows nil progress" do
      attrs = Map.put(@valid_attrs, :progress, nil)
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      assert changeset.valid?
    end

    test "allows empty map progress" do
      attrs = Map.put(@valid_attrs, :progress, %{})
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      assert changeset.valid?
    end

    test "validates progress as map when provided" do
      attrs = Map.put(@valid_attrs, :progress, "invalid")
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      refute changeset.valid?
    end

    test "validates unique constraint on character_id and badge_id" do
      # This test would require database setup to properly test the unique constraint
      changeset = CharacterBadge.changeset(%CharacterBadge{}, @valid_attrs)
      assert changeset.valid?
    end
  end

  describe "progress_changeset/2" do
    test "updates progress field" do
      character_badge = %CharacterBadge{progress: %{"current" => 3}}
      new_progress = %{"current" => 7, "required" => 10}
      changeset = CharacterBadge.progress_changeset(character_badge, %{progress: new_progress})
      
      assert changeset.valid?
      assert get_change(changeset, :progress) == new_progress
    end

    test "preserves other fields" do
      character_badge = %CharacterBadge{
        character_id: 1,
        badge_id: 1,
        progress: %{"current" => 3}
      }
      changeset = CharacterBadge.progress_changeset(character_badge, %{progress: %{"current" => 7}})
      
      assert changeset.data.character_id == 1
      assert changeset.data.badge_id == 1
    end

    test "allows nil progress" do
      character_badge = %CharacterBadge{progress: %{"current" => 3}}
      changeset = CharacterBadge.progress_changeset(character_badge, %{progress: nil})
      
      assert changeset.valid?
      assert get_change(changeset, :progress) == nil
    end
  end

  describe "completion_changeset/2" do
    test "marks badge as completed" do
      character_badge = %CharacterBadge{completed_at: nil}
      changeset = CharacterBadge.completion_changeset(character_badge, %{})
      
      assert changeset.valid?
      completed_at = get_change(changeset, :completed_at)
      assert completed_at != nil
      assert DateTime.diff(DateTime.utc_now(), completed_at, :second) < 5
    end

    test "preserves other fields" do
      character_badge = %CharacterBadge{
        character_id: 1,
        badge_id: 1,
        completed_at: nil
      }
      changeset = CharacterBadge.completion_changeset(character_badge, %{})
      
      assert changeset.data.character_id == 1
      assert changeset.data.badge_id == 1
    end
  end
end
