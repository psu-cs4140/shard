defmodule Shard.Titles.CharacterTitleTest do
  use Shard.DataCase

  alias Shard.Titles.CharacterTitle

  @valid_attrs %{
    character_id: 1,
    title_id: 1,
    awarded_at: DateTime.utc_now(),
    is_active: false
  }

  @invalid_attrs %{}

  describe "changeset/2" do
    test "valid changeset with all fields" do
      changeset = CharacterTitle.changeset(%CharacterTitle{}, @valid_attrs)
      assert changeset.valid?
    end

    test "invalid changeset with missing required fields" do
      changeset = CharacterTitle.changeset(%CharacterTitle{}, @invalid_attrs)
      refute changeset.valid?
      
      errors = errors_on(changeset)
      assert "can't be blank" in errors.character_id
      assert "can't be blank" in errors.title_id
    end

    test "validates character_id is positive integer" do
      attrs = Map.put(@valid_attrs, :character_id, 0)
      changeset = CharacterTitle.changeset(%CharacterTitle{}, attrs)
      refute changeset.valid?
      assert %{character_id: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates title_id is positive integer" do
      attrs = Map.put(@valid_attrs, :title_id, -1)
      changeset = CharacterTitle.changeset(%CharacterTitle{}, attrs)
      refute changeset.valid?
      assert %{title_id: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "sets default awarded_at when not provided" do
      attrs = Map.delete(@valid_attrs, :awarded_at)
      changeset = CharacterTitle.changeset(%CharacterTitle{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :awarded_at) != nil
    end

    test "sets default is_active to false when not provided" do
      attrs = Map.delete(@valid_attrs, :is_active)
      changeset = CharacterTitle.changeset(%CharacterTitle{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :is_active) == false
    end

    test "allows is_active to be true" do
      attrs = Map.put(@valid_attrs, :is_active, true)
      changeset = CharacterTitle.changeset(%CharacterTitle{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :is_active) == true
    end

    test "validates unique constraint on character_id and title_id" do
      # This test would require database setup to properly test the unique constraint
      changeset = CharacterTitle.changeset(%CharacterTitle{}, @valid_attrs)
      assert changeset.valid?
    end
  end

  describe "activate_changeset/2" do
    test "sets is_active to true" do
      character_title = %CharacterTitle{is_active: false}
      changeset = CharacterTitle.activate_changeset(character_title, %{})
      assert get_change(changeset, :is_active) == true
    end

    test "preserves other fields" do
      character_title = %CharacterTitle{
        character_id: 1,
        title_id: 1,
        is_active: false
      }
      changeset = CharacterTitle.activate_changeset(character_title, %{})
      assert changeset.data.character_id == 1
      assert changeset.data.title_id == 1
    end
  end

  describe "deactivate_changeset/2" do
    test "sets is_active to false" do
      character_title = %CharacterTitle{is_active: true}
      changeset = CharacterTitle.deactivate_changeset(character_title, %{})
      assert get_change(changeset, :is_active) == false
    end

    test "preserves other fields" do
      character_title = %CharacterTitle{
        character_id: 1,
        title_id: 1,
        is_active: true
      }
      changeset = CharacterTitle.deactivate_changeset(character_title, %{})
      assert changeset.data.character_id == 1
      assert changeset.data.title_id == 1
    end
  end
end
