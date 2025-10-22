defmodule Shard.Weapons.SeedData.DamageTypesSeeds do
  @moduledoc """
  This module defines some damage types for weapons
  """
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
