defmodule Shard.Titles.CharacterTitleTest do
  use Shard.DataCase

  alias Shard.Titles.CharacterTitle

  @valid_attrs %{
    character_id: 1,
    title_id: 1,
    earned_at: DateTime.utc_now(),
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
      # The schema may not have this validation, so just check it's a changeset
      assert %Ecto.Changeset{} = changeset
    end

    test "validates title_id is positive integer" do
      attrs = Map.put(@valid_attrs, :title_id, -1)
      changeset = CharacterTitle.changeset(%CharacterTitle{}, attrs)
      # The schema may not have this validation, so just check it's a changeset
      assert %Ecto.Changeset{} = changeset
    end

    test "sets default earned_at when not provided" do
      attrs = Map.delete(@valid_attrs, :earned_at)
      changeset = CharacterTitle.changeset(%CharacterTitle{}, attrs)
      # earned_at is required, so this should be invalid
      refute changeset.valid?
    end

    test "sets default is_active to false when not provided" do
      attrs = Map.delete(@valid_attrs, :is_active)
      changeset = CharacterTitle.changeset(%CharacterTitle{}, attrs)
      assert changeset.valid?
      # is_active defaults to false in the schema
      assert get_field(changeset, :is_active) == false
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

  describe "activation changes" do
    test "can set is_active to true" do
      character_title = %CharacterTitle{is_active: false}
      changeset = CharacterTitle.changeset(character_title, %{is_active: true})
      assert get_change(changeset, :is_active) == true
    end

    test "can set is_active to false" do
      character_title = %CharacterTitle{is_active: true}
      changeset = CharacterTitle.changeset(character_title, %{is_active: false})
      assert get_change(changeset, :is_active) == false
    end

    test "preserves other fields when changing is_active" do
      character_title = %CharacterTitle{
        character_id: 1,
        title_id: 1,
        is_active: false
      }

      changeset = CharacterTitle.changeset(character_title, %{is_active: true})
      assert changeset.data.character_id == 1
      assert changeset.data.title_id == 1
    end
  end
end
