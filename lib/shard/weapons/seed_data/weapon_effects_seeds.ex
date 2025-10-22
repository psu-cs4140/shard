defmodule Shard.Weapons.SeedData.WeaponEffectsSeeds do
  @moduledoc """
  This module defines more effects for the flaming sword
  """
  def data do
    [
      # Flaming Sword has Bleeding effect
      %{weapon_id: 4, effect_id: 1},
      # Flaming Sword has Stun effect
      %{weapon_id: 4, effect_id: 3}
    ]
  end
end
