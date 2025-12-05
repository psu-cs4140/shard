defmodule Shard.Map.DoorTest do
  use Shard.DataCase

  alias Shard.Map.Door

  describe "changeset/2" do
    @valid_attrs %{
      from_room_id: 1,
      to_room_id: 2,
      direction: "north",
      door_type: "standard",
      is_locked: false,
      name: nil,
      description: nil,
      key_required: nil,
      properties: %{},
      new_dungeon: false
    }

    test "changeset with valid attributes" do
      changeset = Door.changeset(%Door{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires from_room_id, to_room_id, and direction" do
      changeset = Door.changeset(%Door{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.from_room_id
      assert "can't be blank" in errors.to_room_id
      assert "can't be blank" in errors.direction
    end

    test "validates direction inclusion" do
      invalid_attrs = %{@valid_attrs | direction: "invalid_direction"}
      changeset = Door.changeset(%Door{}, invalid_attrs)
      refute changeset.valid?
      assert %{direction: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid directions" do
      valid_directions = [
        "north", "south", "east", "west", "up", "down",
        "northeast", "northwest", "southeast", "southwest"
      ]

      for direction <- valid_directions do
        attrs = %{@valid_attrs | direction: direction}
        changeset = Door.changeset(%Door{}, attrs)
        assert changeset.valid?, "Expected #{direction} to be valid"
      end
    end

    test "validates door_type inclusion" do
      invalid_attrs = %{@valid_attrs | door_type: "invalid_type"}
      changeset = Door.changeset(%Door{}, invalid_attrs)
      refute changeset.valid?
      assert %{door_type: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid door types" do
      valid_types = ["standard", "gate", "portal", "secret", "locked_gate"]

      for door_type <- valid_types do
        attrs = %{@valid_attrs | door_type: door_type}
        changeset = Door.changeset(%Door{}, attrs)
        assert changeset.valid?, "Expected #{door_type} to be valid"
      end
    end

    test "validates that from_room_id and to_room_id are different" do
      invalid_attrs = %{@valid_attrs | from_room_id: 1, to_room_id: 1}
      changeset = Door.changeset(%Door{}, invalid_attrs)
      refute changeset.valid?
      assert %{to_room_id: ["cannot lead to the same room"]} = errors_on(changeset)
    end

    test "validates name length" do
      long_name = String.duplicate("a", 101)
      invalid_attrs = %{@valid_attrs | name: long_name}
      changeset = Door.changeset(%Door{}, invalid_attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates description length" do
      long_description = String.duplicate("a", 501)
      invalid_attrs = %{@valid_attrs | description: long_description}
      changeset = Door.changeset(%Door{}, invalid_attrs)
      refute changeset.valid?
      assert %{description: ["should be at most 500 character(s)"]} = errors_on(changeset)
    end

    test "validates key_required length" do
      long_key = String.duplicate("a", 101)
      invalid_attrs = %{@valid_attrs | key_required: long_key}
      changeset = Door.changeset(%Door{}, invalid_attrs)
      refute changeset.valid?
      assert %{key_required: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "accepts optional fields" do
      attrs = %{
        @valid_attrs |
        name: "Secret Door",
        description: "A hidden passage",
        key_required: "golden_key",
        properties: %{"hidden" => true},
        new_dungeon: true
      }

      changeset = Door.changeset(%Door{}, attrs)
      assert changeset.valid?
    end
  end

  describe "opposite_direction/1" do
    test "returns correct opposite directions" do
      assert Door.opposite_direction("north") == "south"
      assert Door.opposite_direction("south") == "north"
      assert Door.opposite_direction("east") == "west"
      assert Door.opposite_direction("west") == "east"
      assert Door.opposite_direction("up") == "down"
      assert Door.opposite_direction("down") == "up"
      assert Door.opposite_direction("northeast") == "southwest"
      assert Door.opposite_direction("northwest") == "southeast"
      assert Door.opposite_direction("southeast") == "northwest"
      assert Door.opposite_direction("southwest") == "northeast"
    end

    test "returns same direction for unknown directions" do
      assert Door.opposite_direction("unknown") == "unknown"
      assert Door.opposite_direction("custom") == "custom"
    end
  end
end
