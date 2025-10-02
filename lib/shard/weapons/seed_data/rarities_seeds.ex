defmodule Shard.Weapons.SeedData.RaritiesSeeds do
  alias Shard.Weapons.Rarities

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
