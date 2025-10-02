defmodule Shard.Weapons.SeedData.DamageTypesSeeds do
  alias Shard.Weapons.DamageTypes

  def data do
    [
      %{name: "Slashing"},
      %{name: "Piercing"},
      %{name: "Bludgeoning"},
      %{name: "Fire"},
      %{name: "Cold"},
      %{name: "Lightning"},
      %{name: "Poison"},
      %{name: "Acid"}
    ]
  end
end
