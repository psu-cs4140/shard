defmodule Shard.Seeds.EffectsSeeder do
  alias Shard.Weapons.Effects
  alias Shard.Repo

  def run do
    Shard.Weapons.SeedData.EffectsSeeds.data()
    |> Enum.each(&insert_effect/1)
  end

  defp insert_effect(attrs) do
    case Repo.get_by(Effects, name: attrs.name) do
      nil -> 
        %Effects{}
        |> Effects.changeset(attrs)
        |> Repo.insert!()
      
      _ -> 
        :already_exists
    end
  end
end
