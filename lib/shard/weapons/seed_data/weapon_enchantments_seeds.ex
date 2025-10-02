defmodule Shard.Weapons.SeedData.WeaponEnchantmentsSeeds do
  alias Shard.Weapons.WeaponEnchantments

  def data do
    [
      # Flaming Sword has Flaming enchantment
      %{weapon_id: 4, enchantment_id: 1}
    ]
  end
end
