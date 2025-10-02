defmodule Shard.Weapons.Weapon do
  @moduledoc """
  Weapons context. Contains weapon-related game-logic.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Weapons.Weapons

  @doc """
  Gets a single weapon.
  """
  def get_weapon!(id) do
    Weapons
    |> where([w], w.id == ^id)
    |> select([w], %{id: w.id, name: w.name, damage: w.damage, gold_value: w.gold_value, description: w.description, weapon_class_id: w.weapon_class_id, rarity_id: w.rarity_id})
    |> Repo.one()
  end

  @doc """
  Lists all weapons.
  """
  def list_weapons do
    Repo.all(Weapons)
  end

  @doc """
  Lists weapons by type.
  """
  def list_weapons_by_type(type) do
    Weapons
    |> where([w], w.type == ^type)
    |> Repo.all()
  end

  @doc """
  Generates the starting weapons for the tutorial.
  """
  def get_tutorial_start_weapons() do
    Weapons
    |> where([w], w.id == 2)
    |> select([w], %{id: w.id, name: w.name, damage: w.damage, gold_value: w.gold_value, description: w.description, weapon_class_id: w.weapon_class_id, rarity_id: w.rarity_id})
    |> Repo.one()
  end
end
