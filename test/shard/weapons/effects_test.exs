defmodule Shard.Weapons.EffectsTest do
  use Shard.DataCase

  alias Shard.Weapons.Effects

  describe "changeset/2" do
    test "validates required fields" do
      attrs = %{}
      changeset = Effects.changeset(%Effects{}, attrs)
      assert changeset.valid? == false
      assert %{name: ["can't be blank"]} = errors_on(changeset)
      assert %{modifier_type: ["can't be blank"]} = errors_on(changeset)
      assert %{modifier_value: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid attributes" do
      attrs = %{
        name: "Poison",
        modifier_type: "damage_over_time",
        modifier_value: 5
      }
      changeset = Effects.changeset(%Effects{}, attrs)
      assert changeset.valid?
    end
  end
end
