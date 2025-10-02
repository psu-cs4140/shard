defmodule Shard.Weapons.DamageTypesTest do
  use Shard.DataCase

  alias Shard.Weapons.DamageTypes

  describe "changeset/2" do
    test "validates required fields" do
      attrs = %{}
      changeset = DamageTypes.changeset(%DamageTypes{}, attrs)
      assert changeset.valid? == false
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid attributes" do
      attrs = %{name: "Fire"}
      changeset = DamageTypes.changeset(%DamageTypes{}, attrs)
      assert changeset.valid?
    end
  end
end
