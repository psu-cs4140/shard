defmodule Shard.Weapons.SeedData.WeaponEffectsSeeds do
  alias Shard.Weapons.WeaponEffects

  def data do
    [
      %{weapon_id: 4, effect_id: 1},  # Flaming Sword has Bleeding effect
      %{weapon_id: 4, effect_id: 3}   # Flaming Sword has Stun effect
    ]
  end
end
