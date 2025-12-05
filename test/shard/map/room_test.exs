defmodule Shard.Map.RoomTest do
  use Shard.DataCase

  alias Shard.Map.Room

  describe "changeset/2" do
    @valid_attrs %{
      name: "Test Room",
      description: "A test room for testing",
      x_coordinate: 0,
      y_coordinate: 0,
      z_coordinate: 0,
      is_public: true,
      room_type: "standard",
      properties: %{},
      zone_id: 1
    }

    test "changeset with valid attributes" do
      changeset = Room.changeset(%Room{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires name" do
      changeset = Room.changeset(%Room{}, %{})
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates name length" do
      # Too short
      short_attrs = %{@valid_attrs | name: ""}
      changeset = Room.changeset(%Room{}, short_attrs)
      refute changeset.valid?
      assert %{name: ["should be at least 1 character(s)"]} = errors_on(changeset)

      # Too long
      long_name = String.duplicate("a", 101)
      long_attrs = %{@valid_attrs | name: long_name}
      changeset = Room.changeset(%Room{}, long_attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates description length" do
      long_description = String.duplicate("a", 1001)
      invalid_attrs = %{@valid_attrs | description: long_description}
      changeset = Room.changeset(%Room{}, invalid_attrs)
      refute changeset.valid?
      assert %{description: ["should be at most 1000 character(s)"]} = errors_on(changeset)
    end

    test "validates room_type inclusion" do
      invalid_attrs = %{@valid_attrs | room_type: "invalid_type"}
      changeset = Room.changeset(%Room{}, invalid_attrs)
      refute changeset.valid?
      assert %{room_type: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid room types" do
      valid_types = [
        "standard", "safe_zone", "shop", "dungeon", 
        "treasure_room", "trap_room", "end_room"
      ]

      for room_type <- valid_types do
        attrs = %{@valid_attrs | room_type: room_type}
        changeset = Room.changeset(%Room{}, attrs)
        assert changeset.valid?, "Expected #{room_type} to be valid"
      end
    end

    test "accepts default values" do
      minimal_attrs = %{name: "Minimal Room"}
      changeset = Room.changeset(%Room{}, minimal_attrs)
      assert changeset.valid?

      # Check defaults are applied
      assert get_field(changeset, :x_coordinate) == 0
      assert get_field(changeset, :y_coordinate) == 0
      assert get_field(changeset, :z_coordinate) == 0
      assert get_field(changeset, :is_public) == true
      assert get_field(changeset, :room_type) == "standard"
      assert get_field(changeset, :properties) == %{}
    end

    test "accepts coordinate values" do
      attrs = %{
        @valid_attrs |
        x_coordinate: -10,
        y_coordinate: 25,
        z_coordinate: 5
      }

      changeset = Room.changeset(%Room{}, attrs)
      assert changeset.valid?
    end

    test "accepts properties map" do
      attrs = %{
        @valid_attrs |
        properties: %{
          "lighting" => "dim",
          "temperature" => "cold",
          "special_features" => ["fountain", "statue"]
        }
      }

      changeset = Room.changeset(%Room{}, attrs)
      assert changeset.valid?
    end

    test "accepts boolean fields" do
      attrs = %{@valid_attrs | is_public: false}
      changeset = Room.changeset(%Room{}, attrs)
      assert changeset.valid?
      assert get_field(changeset, :is_public) == false
    end
  end
end
