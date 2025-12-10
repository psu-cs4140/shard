defmodule Shard.Weapons.DamageTypesContextTest do
  use Shard.DataCase

  alias Shard.Weapons.DamageTypes

  describe "get_damage_multiplier/2" do
    test "returns 1.0 for unknown damage type" do
      target_resistances = %{"fire" => 0.5, "ice" => 2.0}
      multiplier = DamageTypes.get_damage_multiplier("lightning", target_resistances)
      
      assert multiplier == 1.0
    end

    test "returns correct multiplier for known damage type" do
      target_resistances = %{"fire" => 0.5, "ice" => 2.0}
      
      fire_multiplier = DamageTypes.get_damage_multiplier("fire", target_resistances)
      assert fire_multiplier == 0.5
      
      ice_multiplier = DamageTypes.get_damage_multiplier("ice", target_resistances)
      assert ice_multiplier == 2.0
    end

    test "handles empty resistances map" do
      multiplier = DamageTypes.get_damage_multiplier("fire", %{})
      assert multiplier == 1.0
    end

    test "handles list of tuples for resistances" do
      target_resistances = [{"fire", 0.8}, {"ice", 1.2}]
      
      fire_multiplier = DamageTypes.get_damage_multiplier("fire", target_resistances)
      assert fire_multiplier == 0.8
      
      ice_multiplier = DamageTypes.get_damage_multiplier("ice", target_resistances)
      assert ice_multiplier == 1.2
    end
  end
end
