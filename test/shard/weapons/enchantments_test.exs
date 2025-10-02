defmodule Shard.Weapons.EnchantmentsTest do
  use Shard.DataCase

  alias Shard.Weapons.Enchantments

  describe "changeset/2" do
    test "validates required fields" do
      attrs = %{}
      changeset = Enchantments.changeset(%Enchantments{}, attrs)
      assert changeset.valid? == false
      assert %{name: ["can't be blank"]} = errors_on(changeset)
      assert %{modifier_type: ["can't be blank"]} = errors_on(changeset)
      assert %{modifier_value: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid attributes" do
      attrs = %{
        name: "Flaming",
        modifier_type: "fire_damage",
        modifier_value: "1d6"
      }

      changeset = Enchantments.changeset(%Enchantments{}, attrs)
      assert changeset.valid?
    end
  end
end
