defmodule Shard.Weapons.SeedData.EnchantmentsSeeds do
  @moduledoc """
  This module defines different enchantments
  """

  def data do
    [
      %{name: "Flaming", modifier_type: "fire_damage", modifier_value: "+5"},
      %{name: "Freezing", modifier_type: "cold_damage", modifier_value: "+3"},
      %{name: "Sharp", modifier_type: "damage_bonus", modifier_value: "+2"},
      %{name: "Vampiric", modifier_type: "lifesteal", modifier_value: "3%"},
      %{name: "Thunderous", modifier_type: "lightning_damage", modifier_value: "+4"}
    ]
  end
end
