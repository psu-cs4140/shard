defmodule Shard.Map.ZoneTest do
  use Shard.DataCase

  alias Shard.Map.Zone

  describe "changeset/2" do
    test "validates required fields" do
      changeset = Zone.changeset(%Zone{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.slug
    end

    test "validates name length" do
      # Too short
      attrs = %{name: "A", slug: "test"}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{name: ["should be at least 2 character(s)"]} = errors_on(changeset)

      # Too long
      long_name = String.duplicate("A", 101)
      attrs = %{name: long_name, slug: "test"}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates slug format" do
      # Valid slug
      attrs = %{name: "Test Zone", slug: "test-zone-123"}
      changeset = Zone.changeset(%Zone{}, attrs)
      assert changeset.valid?

      # Invalid slug with uppercase
      attrs = %{name: "Test Zone", slug: "Test-Zone"}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{slug: ["must be lowercase alphanumeric with hyphens"]} = errors_on(changeset)

      # Invalid slug with spaces
      attrs = %{name: "Test Zone", slug: "test zone"}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{slug: ["must be lowercase alphanumeric with hyphens"]} = errors_on(changeset)

      # Invalid slug with special characters
      attrs = %{name: "Test Zone", slug: "test@zone"}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{slug: ["must be lowercase alphanumeric with hyphens"]} = errors_on(changeset)
    end

    test "validates slug length" do
      # Too short
      attrs = %{name: "Test Zone", slug: "a"}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{slug: ["should be at least 2 character(s)"]} = errors_on(changeset)

      # Too long
      long_slug = String.duplicate("a", 101)
      attrs = %{name: "Test Zone", slug: long_slug}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{slug: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates description length" do
      long_description = String.duplicate("A", 1001)
      attrs = %{name: "Test Zone", slug: "test-zone", description: long_description}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{description: ["should be at most 1000 character(s)"]} = errors_on(changeset)
    end

    test "validates zone_type inclusion" do
      valid_types = ["standard", "dungeon", "town", "wilderness", "raid", "pvp", "safe_zone"]

      for type <- valid_types do
        attrs = %{name: "Test Zone", slug: "test-zone", zone_type: type}
        changeset = Zone.changeset(%Zone{}, attrs)
        assert changeset.valid?
      end

      # Invalid type
      attrs = %{name: "Test Zone", slug: "test-zone", zone_type: "invalid"}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{zone_type: ["is invalid"]} = errors_on(changeset)
    end

    test "validates level constraints" do
      # Valid levels
      attrs = %{name: "Test Zone", slug: "test-zone", min_level: 1, max_level: 10}
      changeset = Zone.changeset(%Zone{}, attrs)
      assert changeset.valid?

      # Invalid min_level
      attrs = %{name: "Test Zone", slug: "test-zone", min_level: 0}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{min_level: ["must be greater than or equal to 1"]} = errors_on(changeset)

      # Invalid max_level
      attrs = %{name: "Test Zone", slug: "test-zone", max_level: 0}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      errors = errors_on(changeset)
      assert "must be greater than or equal to 1" in errors.max_level
    end

    test "validates level range" do
      attrs = %{name: "Test Zone", slug: "test-zone", min_level: 10, max_level: 5}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{max_level: ["must be greater than or equal to min_level"]} = errors_on(changeset)
    end

    test "validates display_order" do
      attrs = %{name: "Test Zone", slug: "test-zone", display_order: -1}
      changeset = Zone.changeset(%Zone{}, attrs)
      refute changeset.valid?
      assert %{display_order: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "accepts valid changeset" do
      attrs = %{
        name: "Tutorial Area",
        slug: "tutorial-area",
        description: "A safe area for new players",
        zone_type: "safe_zone",
        min_level: 1,
        max_level: 5,
        is_public: true,
        is_active: true,
        display_order: 1
      }

      changeset = Zone.changeset(%Zone{}, attrs)
      assert changeset.valid?
    end
  end

  describe "zone_types/0" do
    test "returns list of valid zone types" do
      types = Zone.zone_types()
      expected_types = ["standard", "dungeon", "town", "wilderness", "raid", "pvp", "safe_zone"]
      assert types == expected_types
    end
  end
end
