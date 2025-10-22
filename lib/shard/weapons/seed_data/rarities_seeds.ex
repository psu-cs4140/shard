defmodule Shard.Weapons.SeedData.RaritiesSeeds do
  @moduledoc """
  This module defines the types up rarities:
  - common
  - uncommon
  - rare
  - epic
  - legendary
  """

  def data do
    [
      %{name: "Common"},
      %{name: "Uncommon"},
      %{name: "Rare"},
      %{name: "Epic"},
      %{name: "Legendary"}
    ]
  end
end
