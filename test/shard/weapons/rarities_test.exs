defmodule Shard.Weapons.RaritiesTest do
  use Shard.DataCase

  alias Shard.Weapons.Rarities

  describe "changeset/2" do
    test "validates required fields" do
      attrs = %{}
      changeset = Rarities.changeset(%Rarities{}, attrs)
      assert changeset.valid? == false
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid attributes" do
      attrs = %{name: "Legendary"}
      changeset = Rarities.changeset(%Rarities{}, attrs)
      assert changeset.valid?
    end
  end
end
