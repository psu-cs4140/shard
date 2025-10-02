defmodule Shard.Weapons.ClassesTest do
  use Shard.DataCase

  alias Shard.Weapons.Classes

  describe "changeset/2" do
    test "validates required fields" do
      attrs = %{}
      changeset = Classes.changeset(%Classes{}, attrs)
      assert changeset.valid? == false
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid attributes" do
      attrs = %{name: "Sword"}
      changeset = Classes.changeset(%Classes{}, attrs)
      assert changeset.valid?
    end
  end
end
