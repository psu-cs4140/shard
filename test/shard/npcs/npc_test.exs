defmodule Shard.Npcs.NpcTest do
  use Shard.DataCase

  alias Shard.Npcs.Npc

  describe "changeset/2" do
    @valid_attrs %{
      name: "Test NPC",
      description: "A test NPC for testing",
      level: 5,
      health: 80,
      max_health: 100,
      mana: 40,
      max_mana: 50,
      strength: 15,
      dexterity: 12,
      intelligence: 10,
      constitution: 14,
      experience_reward: 50,
      gold_reward: 25,
      npc_type: "neutral",
      dialogue: "Hello, traveler!",
      inventory: %{"gold" => 100},
      location_x: 5,
      location_y: 10,
      location_z: 0,
      room_id: 1,
      is_active: true,
      respawn_time: 300,
      faction: "neutral",
      aggression_level: 0,
      movement_pattern: "stationary",
      properties: %{"friendly" => true}
    }

    test "changeset with valid attributes" do
      changeset = Npc.changeset(%Npc{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires name" do
      changeset = Npc.changeset(%Npc{}, %{})
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates name length" do
      # Too short
      short_attrs = %{@valid_attrs | name: "A"}
      changeset = Npc.changeset(%Npc{}, short_attrs)
      refute changeset.valid?
      assert %{name: ["should be at least 2 character(s)"]} = errors_on(changeset)

      # Too long
      long_name = String.duplicate("a", 101)
      long_attrs = %{@valid_attrs | name: long_name}
      changeset = Npc.changeset(%Npc{}, long_attrs)
      refute changeset.valid?
      assert %{name: ["should be at most 100 character(s)"]} = errors_on(changeset)
    end

    test "validates npc_type inclusion" do
      invalid_attrs = %{@valid_attrs | npc_type: "invalid_type"}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{npc_type: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid npc types" do
      valid_types = ["neutral", "friendly", "hostile", "merchant", "quest_giver"]

      for npc_type <- valid_types do
        attrs = %{@valid_attrs | npc_type: npc_type}
        changeset = Npc.changeset(%Npc{}, attrs)
        assert changeset.valid?, "Expected #{npc_type} to be valid"
      end
    end

    test "validates movement_pattern inclusion" do
      invalid_attrs = %{@valid_attrs | movement_pattern: "invalid_pattern"}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{movement_pattern: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid movement patterns" do
      valid_patterns = ["stationary", "patrol", "random", "follow"]

      for pattern <- valid_patterns do
        attrs = %{@valid_attrs | movement_pattern: pattern}
        changeset = Npc.changeset(%Npc{}, attrs)
        assert changeset.valid?, "Expected #{pattern} to be valid"
      end
    end

    test "validates level range" do
      # Too low
      invalid_attrs = %{@valid_attrs | level: 0}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{level: ["must be greater than 0"]} = errors_on(changeset)

      # Too high
      invalid_attrs = %{@valid_attrs | level: 101}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{level: ["must be less than or equal to 100"]} = errors_on(changeset)
    end

    test "validates health is non-negative" do
      invalid_attrs = %{@valid_attrs | health: -1}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{health: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "validates max_health is positive" do
      invalid_attrs = %{@valid_attrs | max_health: 0}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{max_health: ["must be greater than 0"]} = errors_on(changeset)
    end

    test "validates mana is non-negative" do
      invalid_attrs = %{@valid_attrs | mana: -1}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{mana: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "validates max_mana is non-negative" do
      invalid_attrs = %{@valid_attrs | max_mana: -1}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{max_mana: ["must be greater than or equal to 0"]} = errors_on(changeset)
    end

    test "validates aggression_level range" do
      # Too low
      invalid_attrs = %{@valid_attrs | aggression_level: -1}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{aggression_level: ["must be greater than or equal to 0"]} = errors_on(changeset)

      # Too high
      invalid_attrs = %{@valid_attrs | aggression_level: 11}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{aggression_level: ["must be less than or equal to 10"]} = errors_on(changeset)
    end

    test "validates health does not exceed max_health" do
      invalid_attrs = %{@valid_attrs | health: 150, max_health: 100}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{health: ["cannot exceed max health"]} = errors_on(changeset)
    end

    test "validates mana does not exceed max_mana" do
      invalid_attrs = %{@valid_attrs | mana: 80, max_mana: 50}
      changeset = Npc.changeset(%Npc{}, invalid_attrs)
      refute changeset.valid?
      assert %{mana: ["cannot exceed max mana"]} = errors_on(changeset)
    end

    test "accepts health equal to max_health" do
      attrs = %{@valid_attrs | health: 100, max_health: 100}
      changeset = Npc.changeset(%Npc{}, attrs)
      assert changeset.valid?
    end

    test "accepts mana equal to max_mana" do
      attrs = %{@valid_attrs | mana: 50, max_mana: 50}
      changeset = Npc.changeset(%Npc{}, attrs)
      assert changeset.valid?
    end

    test "accepts default values" do
      minimal_attrs = %{name: "Minimal NPC"}
      changeset = Npc.changeset(%Npc{}, minimal_attrs)
      assert changeset.valid?

      # Check defaults are applied
      assert get_field(changeset, :level) == 1
      assert get_field(changeset, :health) == 100
      assert get_field(changeset, :max_health) == 100
      assert get_field(changeset, :mana) == 50
      assert get_field(changeset, :max_mana) == 50
      assert get_field(changeset, :npc_type) == "neutral"
      assert get_field(changeset, :is_active) == true
      assert get_field(changeset, :aggression_level) == 0
      assert get_field(changeset, :movement_pattern) == "stationary"
    end

    test "accepts map fields" do
      attrs = %{
        @valid_attrs |
        inventory: %{"sword" => 1, "potion" => 3},
        properties: %{"special_ability" => "fireball", "weakness" => "water"}
      }

      changeset = Npc.changeset(%Npc{}, attrs)
      assert changeset.valid?
    end

    test "accepts datetime fields" do
      now = DateTime.utc_now()
      attrs = Map.put(@valid_attrs, :last_death_at, now)
      changeset = Npc.changeset(%Npc{}, attrs)
      assert changeset.valid?
    end

    test "accepts coordinate values" do
      attrs = %{
        @valid_attrs |
        location_x: -10,
        location_y: 25,
        location_z: 5
      }

      changeset = Npc.changeset(%Npc{}, attrs)
      assert changeset.valid?
    end
  end
end
