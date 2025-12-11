defmodule Shard.Skills.SkillTreeTest do
  use Shard.DataCase

  alias Shard.Skills.SkillTree

  describe "changeset/2" do
    test "validates required fields" do
      attrs = %{}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid attributes" do
      attrs = %{
        name: "Combat Skills",
        description: "Skills related to combat and warfare",
        is_active: true
      }
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
    end

    test "validates name length" do
      attrs = %{name: "a"}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      refute changeset.valid?
      assert %{name: ["should be at least 2 character(s)"]} = errors_on(changeset)

      attrs = %{name: String.duplicate("a", 101)}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates name uniqueness constraint structure" do
      attrs = %{name: "Unique Tree"}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
      # The actual uniqueness would be enforced at the database level
    end

    test "sets default values" do
      attrs = %{name: "Test Tree"}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
      # is_active defaults to true if not specified
      assert get_change(changeset, :is_active) == nil  # No change means using default
    end

    test "accepts explicit is_active value" do
      attrs = %{name: "Inactive Tree", is_active: false}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :is_active) == false
    end

    test "accepts description" do
      attrs = %{
        name: "Magic Skills",
        description: "Skills related to magical abilities and spellcasting"
      }
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :description) == "Skills related to magical abilities and spellcasting"
    end

    test "handles nil description" do
      attrs = %{name: "Simple Tree", description: nil}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
    end

    test "handles empty description" do
      attrs = %{name: "Empty Desc Tree", description: ""}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
    end
  end

  describe "schema" do
    test "has correct fields" do
      skill_tree = %SkillTree{
        name: "Test Tree",
        description: "A test skill tree",
        is_active: true
      }

      assert skill_tree.name == "Test Tree"
      assert skill_tree.description == "A test skill tree"
      assert skill_tree.is_active == true
    end

    test "has default values" do
      skill_tree = %SkillTree{}
      assert skill_tree.is_active == true  # Default value
      assert skill_tree.name == nil
      assert skill_tree.description == nil
    end

    test "supports associations" do
      skill_tree = %SkillTree{}
      # Test that the struct has the expected association fields
      # (The actual associations would be defined in the schema)
      assert Map.has_key?(skill_tree, :id)
      assert Map.has_key?(skill_tree, :inserted_at)
      assert Map.has_key?(skill_tree, :updated_at)
    end
  end

  describe "edge cases" do
    test "handles very long valid name" do
      attrs = %{name: String.duplicate("a", 100)}  # Max length
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
    end

    test "handles minimum valid name length" do
      attrs = %{name: "ab"}  # Min length
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
    end

    test "handles special characters in name" do
      attrs = %{name: "Combat & Magic Skills"}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
    end

    test "handles unicode characters in name" do
      attrs = %{name: "魔法技能树"}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
    end

    test "handles very long description" do
      long_description = String.duplicate("This is a very detailed description. ", 50)
      attrs = %{name: "Detailed Tree", description: long_description}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
    end
  end

  describe "boolean handling" do
    test "accepts true for is_active" do
      attrs = %{name: "Active Tree", is_active: true}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
      # When setting to the default value (true), Ecto doesn't track it as a change
      assert get_change(changeset, :is_active) == nil
      # But the data should still have the correct value
      assert changeset.data.is_active == true
    end

    test "accepts false for is_active" do
      attrs = %{name: "Inactive Tree", is_active: false}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      assert changeset.valid?
      assert get_change(changeset, :is_active) == false
    end

    test "handles string boolean values" do
      attrs = %{name: "String Bool Tree", is_active: "true"}
      changeset = SkillTree.changeset(%SkillTree{}, attrs)
      # Ecto should cast string "true" to boolean true
      assert changeset.valid?
    end
  end
end
