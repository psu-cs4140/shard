defmodule Shard.Users.PlayerZoneTest do
  use Shard.DataCase

  alias Shard.Users.PlayerZone

  describe "changeset/2" do
    @valid_attrs %{
      zone_name: "Test Zone",
      instance_type: "singleplayer",
      zone_instance_id: "zone-instance-123",
      user_id: 1,
      zone_id: 1
    }

    test "changeset with valid attributes" do
      changeset = PlayerZone.changeset(%PlayerZone{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires all fields" do
      changeset = PlayerZone.changeset(%PlayerZone{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.zone_name
      assert "can't be blank" in errors.instance_type
      assert "can't be blank" in errors.zone_instance_id
      assert "can't be blank" in errors.user_id
      assert "can't be blank" in errors.zone_id
    end

    test "validates instance_type inclusion" do
      invalid_attrs = %{@valid_attrs | instance_type: "invalid_type"}
      changeset = PlayerZone.changeset(%PlayerZone{}, invalid_attrs)
      refute changeset.valid?
      assert %{instance_type: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid instance types" do
      for instance_type <- ["singleplayer", "multiplayer"] do
        attrs = %{@valid_attrs | instance_type: instance_type}
        changeset = PlayerZone.changeset(%PlayerZone{}, attrs)
        assert changeset.valid?, "Expected #{instance_type} to be valid"
      end
    end

    test "validates zone_name length" do
      # Too short
      short_attrs = %{@valid_attrs | zone_name: "A"}
      changeset = PlayerZone.changeset(%PlayerZone{}, short_attrs)
      refute changeset.valid?
      assert %{zone_name: ["should be at least 2 character(s)"]} = errors_on(changeset)

      # Too long
      long_name = String.duplicate("a", 101)
      long_attrs = %{@valid_attrs | zone_name: long_name}
      changeset = PlayerZone.changeset(%PlayerZone{}, long_attrs)
      refute changeset.valid?
      assert %{zone_name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates zone_instance_id length" do
      # Too short
      short_attrs = %{@valid_attrs | zone_instance_id: "A"}
      changeset = PlayerZone.changeset(%PlayerZone{}, short_attrs)
      refute changeset.valid?
      assert %{zone_instance_id: ["should be at least 2 character(s)"]} = errors_on(changeset)

      # Too long
      long_id = String.duplicate("a", 101)
      long_attrs = %{@valid_attrs | zone_instance_id: long_id}
      changeset = PlayerZone.changeset(%PlayerZone{}, long_attrs)
      refute changeset.valid?
      assert %{zone_instance_id: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates foreign key constraints are present" do
      changeset = PlayerZone.changeset(%PlayerZone{}, @valid_attrs)
      
      # Check that foreign key constraints are present
      assert Enum.any?(changeset.constraints, fn constraint ->
        constraint.type == :foreign_key and constraint.field == :user_id
      end)
      
      assert Enum.any?(changeset.constraints, fn constraint ->
        constraint.type == :foreign_key and constraint.field == :zone_id
      end)
    end

    test "validates unique constraint for user, zone, and instance type" do
      changeset = PlayerZone.changeset(%PlayerZone{}, @valid_attrs)
      
      # Check that unique constraint is present
      assert Enum.any?(changeset.constraints, fn constraint ->
        constraint.type == :unique
      end)
    end

    test "accepts valid zone names and instance IDs" do
      attrs = %{
        @valid_attrs |
        zone_name: "Crystal Caves",
        zone_instance_id: "crystal-caves-sp-user-123"
      }

      changeset = PlayerZone.changeset(%PlayerZone{}, attrs)
      assert changeset.valid?
    end
  end

  describe "instance_types/0" do
    test "returns list of valid instance types" do
      types = PlayerZone.instance_types()
      assert types == ["singleplayer", "multiplayer"]
    end
  end
end
