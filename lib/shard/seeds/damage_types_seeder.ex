defmodule Shard.Seeds.DamageTypesSeeder do
  alias Shard.Weapons.DamageTypes
  alias Shard.Repo

  def run do
    Shard.Weapons.SeedData.DamageTypesSeeds.data()
    |> Enum.each(&insert_damage_type/1)
  end

  defp insert_damage_type(attrs) do
    case Repo.get_by(DamageTypes, name: attrs.name) do
      nil -> 
        %DamageTypes{}
        |> DamageTypes.changeset(attrs)
        |> Repo.insert!()
      
      _ -> 
        :already_exists
    end
  end
end
