defmodule Shard.Weapons.WeaponEffectsTest do
  use Shard.DataCase

  alias Shard.Weapons.WeaponEffects

  describe "changeset/2" do
    test "accepts empty attributes" do
      attrs = %{}
      changeset = WeaponEffects.changeset(%WeaponEffects{}, attrs)
      assert changeset.valid?
    end
  end
end
