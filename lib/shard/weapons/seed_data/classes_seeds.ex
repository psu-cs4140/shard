defmodule Shard.Weapons.SeedData.ClassesSeeds do
  alias Shard.Weapons.Classes

  def data do
    [
      %{name: "Dagger", damage_type_id: 1},
      %{name: "Sword", damage_type_id: 1},
      %{name: "Axe", damage_type_id: 1},
      %{name: "Mace", damage_type_id: 3},
      %{name: "Spear", damage_type_id: 2},
      %{name: "Bow", damage_type_id: 2},
      %{name: "Staff", damage_type_id: 3}
    ]
  end
end
