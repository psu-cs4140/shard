defmodule Shard.Map.ZoneTest do
  use Shard.DataCase

  alias Shard.Map.Zone

  describe "changeset/2" do
    @valid_attrs %{
      name: "Test Zone",
      slug: "test-zone",
      description: "A test zone for testing",
      zone_type: "standard",
      min_level: 1,
      max_level: 10,
      is_public: true,
      is_active: true,
      properties: %{},
      display_order: 0
    }

    test "changeset with valid attributes" do
      changeset = Zone.changeset(%Zone{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires name and slug" do
      changeset = Zone.changeset(%Zone{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.name
      assert "can't be blank" in errors.slug
    end

    test "validates name length" do
      # Too short
      short_attrs = %{@valid_attrs | name: "A"}
      changeset = Zone.changeset(%Zone{}, short_attrs)
      refute changeset.valid?
      assert %{name: ["should be at least 2 character(s)"]} = errors_on(changeset)

      # Too long
      long_name = String.duplicate("a", 101)
      long_attrs = %{@valid_attrs | name: long_name}
      changeset = Zone.changeset(%Zone{}, long_attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates slug length" do
      # Too short
      short_attrs = %{@valid_attrs | slug: "a"}
      changeset = Zone.changeset(%Zone{}, short_attrs)
      refute changeset.valid?
      assert %{slug: ["should be at least 2 character(s)"]} = errors_on(changeset)

      # Too long
      long_slug = String.duplicate("a", 101)
      long_attrs = %{@valid_attrs | slug: long_slug}
      changeset = Zone.changeset(%Zone{}, long_attrs)
      refute changeset.valid?
      assert %{slug: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates slug format" do
      invalid_slugs = [
        "Test Zone",  # spaces
        "test_zone",  # underscores
        "test.zone",  # dots
        "Test-Zone",  # uppercase
        "test-zone!"  # special chars
      ]

      for slug <- invalid_slugs do
        attrs = %{@valid_attrs | slug: slug}
        changeset = Zone.changeset(%Zone{}, attrs)
        refute changeset.valid?, "Expected #{slug} to be invalid"
        assert %{slug: [_]} = errors_on(changeset)
      end
    end

    test "accepts valid slug formats" do
      valid_slugs = [
        "test-zone",
        "zone1",
        "my-awesome-zone",
        "zone-123",
        "a-b-c-d-e"
      ]

      for slug <- valid_slugs do
        attrs = %{@valid_attrs | slug: slug}
        changeset = Zone.changeset(%Zone{}, attrs)
        assert changeset.valid?, "Expected #{slug} to be valid"
      end
    end

    test "validates description length" do
      long_description = String.duplicate("a", 1001)
      invalid_attrs = %{@valid_attrs | description: long_description}
      changeset = Zone.changeset(%Zone{}, invalid_attrs)
      refute changeset.valid?
      assert %{description: ["should be at most 1000 character(s)"]} = errors_on(changeset)
    end

    test "validates zone_type inclusion" do
      invalid_attrs = %{@valid_attrs | zone_type: "invalid_type"}
      changeset = Zone.changeset(%Zone{}, invalid_attrs)
      refute changeset.valid?
      assert %{zone_type: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid zone types" do
      valid_types = ["standard", "dungeon", "town", "wilderness", "raid", "pvp", "safe_zone"]

      for zone_type <- valid_types do
        attrs = %{@valid_attrs | zone_type: zone_type}
        changeset = Zone.changeset(%Zone{}, attrs)
        assert changeset.valid?, "Expected #{zone_type} to be valid"
      end
    end

    test "validates min_level is positive" do
      invalid_attrs = %{@valid_attrs | min_level: 0}
      changeset = Zone.changeset(%Zone{}, invalid_attrs)
      refute changeset.valid?
      assert %{min_level: ["must be greater than or equal to 1"]} = errors_on(changeset)
    end

    test "validates max_level is positive" do
      invalid_attrs = %{@valid_attrs | max_level: 0}
      changeset = Zone.changeset(%Zone{}, invalid_attrs)
      refute changeset.valid?
      errors = errors_on(changeset)
      assert "must be greater than or equal to 1" in errors.max_level
    end

    test "validates level range - max_level >= min_level" do
      invalid_attrs = %{@valid_attrs | min_level: 10, max_level: 5}
      changeset = Zone.changeset(%Zone{}, invalid_attrs)
      refute changeset.valid?
      assert %{max_level: ["must be greater than or equal to min_level"]} = errors_on(changeset)
    end

    test "accepts equal min and max levels" do
      attrs = %{@valid_attrs | min_level: 5, max_level: 5}
      changeset = Zone.changeset(%Zone{}, attrs)
      assert changeset.valid?
    end

    test "validates display_order is non-negative" do
      invalid_attrs = %{@valid_attrs | display_order: -1}
      changeset = Zone.changeset(%Zone{}, invalid_attrs)
      refute changeset.valid?
      assert %{display_order: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "accepts default values" do
      minimal_attrs = %{name: "Minimal Zone", slug: "minimal-zone"}
      changeset = Zone.changeset(%Zone{}, minimal_attrs)
      assert changeset.valid?

      # Check defaults are applied
      assert get_field(changeset, :zone_type) == "standard"
      assert get_field(changeset, :min_level) == 1
      assert get_field(changeset, :is_public) == true
      assert get_field(changeset, :is_active) == true
      assert get_field(changeset, :properties) == %{}
      assert get_field(changeset, :display_order) == 0
    end

    test "accepts properties map" do
      attrs = %{
        @valid_attrs |
        properties: %{
          "weather" => "rainy",
          "difficulty" => "hard",
          "special_rules" => ["no_magic", "permadeath"]
        }
      }

      changeset = Zone.changeset(%Zone{}, attrs)
      assert changeset.valid?
    end
  end

  describe "zone_types/0" do
    test "returns list of valid zone types" do
      types = Zone.zone_types()
      assert is_list(types)
      assert "standard" in types
      assert "dungeon" in types
      assert "safe_zone" in types
    end
  end
end
