defmodule Shard.Weapons.SeedData.EffectsSeeds do
  def data do
    [
      %{name: "Bleeding", modifier_type: "damage_over_time", modifier_value: 3},
      %{name: "Knockback", modifier_type: "push_back", modifier_value: 2},
      %{name: "Stun", modifier_type: "stun_chance", modifier_value: 10},
      %{name: "Life Steal", modifier_type: "lifesteal_percent", modifier_value: 5}
    ]
  end
end
