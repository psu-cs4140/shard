defmodule Shard.WeaponsTest do
  use Shard.DataCase

  # Note: Weapons module doesn't exist yet, so these are placeholder tests
  # that test the weapon-related schemas that do exist

  alias Shard.Weapons.{DamageTypes, Effects, Weapons, Rarities, Enchantments, Classes}

  describe "weapon schemas" do
    test "DamageTypes schema exists" do
      assert %DamageTypes{} = %DamageTypes{}
    end

    test "Effects schema exists" do
      assert %Effects{} = %Effects{}
    end

    test "Weapons schema exists" do
      assert %Weapons{} = %Weapons{}
    end

    test "Rarities schema exists" do
      assert %Rarities{} = %Rarities{}
    end

    test "Enchantments schema exists" do
      assert %Enchantments{} = %Enchantments{}
    end

    test "Classes schema exists" do
      assert %Classes{} = %Classes{}
    end
  end
end
