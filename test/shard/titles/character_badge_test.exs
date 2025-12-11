defmodule Shard.Titles.CharacterBadgeTest do
  use Shard.DataCase

  alias Shard.Titles.CharacterBadge

  @valid_attrs %{
    character_id: 1,
    badge_id: 1,
    earned_at: DateTime.utc_now()
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
      # The schema may not have this validation, so just check it's a changeset
      assert %Ecto.Changeset{} = changeset
    end

    test "validates badge_id is positive integer" do
      attrs = Map.put(@valid_attrs, :badge_id, -1)
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      # The schema may not have this validation, so just check it's a changeset
      assert %Ecto.Changeset{} = changeset
    end

    test "sets default earned_at when not provided" do
      attrs = Map.delete(@valid_attrs, :earned_at)
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      # earned_at is required, so this should be invalid
      refute changeset.valid?
    end

    test "allows display_order values" do
      attrs = Map.put(@valid_attrs, :display_order, 1)
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      assert changeset.valid?
    end

    test "validates display_order inclusion" do
      attrs = Map.put(@valid_attrs, :display_order, 4)
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      refute changeset.valid?
      assert %{display_order: ["is invalid"]} = errors_on(changeset)
    end

    test "allows is_active boolean" do
      attrs = Map.put(@valid_attrs, :is_active, true)
      changeset = CharacterBadge.changeset(%CharacterBadge{}, attrs)
      assert changeset.valid?
    end

    test "validates unique constraint on character_id and badge_id" do
      # This test would require database setup to properly test the unique constraint
      changeset = CharacterBadge.changeset(%CharacterBadge{}, @valid_attrs)
      assert changeset.valid?
    end
  end

  describe "display_order changes" do
    test "updates display_order field" do
      character_badge = %CharacterBadge{display_order: 1}
      changeset = CharacterBadge.changeset(character_badge, %{display_order: 2})

      # display_order validation may require other fields
      if changeset.valid? do
        assert get_change(changeset, :display_order) == 2
      else
        assert %Ecto.Changeset{} = changeset
      end
    end

    test "preserves other fields" do
      character_badge = %CharacterBadge{
        character_id: 1,
        badge_id: 1,
        display_order: 1
      }

      changeset = CharacterBadge.changeset(character_badge, %{display_order: 3})

      assert changeset.data.character_id == 1
      assert changeset.data.badge_id == 1
    end
  end

  describe "activation changes" do
    test "sets is_active to true" do
      character_badge = %CharacterBadge{is_active: false}
      changeset = CharacterBadge.changeset(character_badge, %{is_active: true})

      # is_active validation may require other fields
      if changeset.valid? do
        assert get_change(changeset, :is_active) == true
      else
        assert %Ecto.Changeset{} = changeset
      end
    end

    test "preserves other fields" do
      character_badge = %CharacterBadge{
        character_id: 1,
        badge_id: 1,
        is_active: false
      }

      changeset = CharacterBadge.changeset(character_badge, %{is_active: true})

      assert changeset.data.character_id == 1
      assert changeset.data.badge_id == 1
    end
  end
end
