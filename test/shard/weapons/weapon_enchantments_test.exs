defmodule Shard.Weapons.WeaponEnchantmentsTest do
  use Shard.DataCase

  alias Shard.Weapons.WeaponEnchantments

  describe "changeset/2" do
    test "validates required fields" do
      attrs = %{}
      changeset = WeaponEnchantments.changeset(%WeaponEnchantments{}, attrs)
      refute changeset.valid?

      assert errors_on(changeset) == %{
               weapon_id: ["can't be blank"],
               enchantment_id: ["can't be blank"]
             }
    end

    test "accepts valid attributes" do
      attrs = %{
        weapon_id: 1,
        enchantment_id: 1
      }

      changeset = WeaponEnchantments.changeset(%WeaponEnchantments{}, attrs)
      assert changeset.valid?
    end
  end

  describe "schema" do
    test "has the correct fields" do
      weapon_enchantment = %WeaponEnchantments{
        weapon_id: 1,
        enchantment_id: 1
      }

      assert weapon_enchantment.weapon_id == 1
      assert weapon_enchantment.enchantment_id == 1
    end
  end
end
