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
    |> select([w], %{
      id: w.id,
      name: w.name,
      damage: w.damage,
      gold_value: w.gold_value,
      description: w.description,
      weapon_class_id: w.weapon_class_id,
      rarity_id: w.rarity_id
    })
    |> Repo.one()
  end

  @doc """
  Gets a weapon with its stats from the items table.
  """
  def get_weapon_with_stats!(id) do
    alias Shard.Items.Item

    Item
    |> where([i], i.id == ^id and i.item_type == "weapon")
    |> Repo.one!()
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
    |> select([w], %{
      id: w.id,
      name: w.name,
      damage: w.damage,
      gold_value: w.gold_value,
      description: w.description,
      weapon_class_id: w.weapon_class_id,
      rarity_id: w.rarity_id
    })
    |> Repo.one()
  end

  @doc """
  Calculate total weapon damage including stats bonuses.
  """
  def calculate_total_damage(weapon) do
    alias Shard.Items.Item

    base_damage = weapon.damage || 0
    attack_power = Item.get_stat(weapon, "attack_power")
    
    base_damage + attack_power
  end

  @doc """
  Get weapon stats summary for display.
  """
  def get_weapon_stats_summary(weapon) do
    alias Shard.Items.Item

    stats = Item.get_total_stats(weapon)
    
    %{
      attack_power: Map.get(stats, "attack_power", 0),
      critical_chance: Map.get(stats, "critical_chance", 0),
      critical_damage: Map.get(stats, "critical_damage", 0),
      attack_speed: Map.get(stats, "attack_speed", 0),
      accuracy: Map.get(stats, "accuracy", 0),
      durability: Map.get(stats, "durability", 100)
    }
  end

  @doc """
  Lists weapons with their stats.
  """
  def list_weapons_with_stats do
    alias Shard.Items.Item

    Item
    |> where([i], i.item_type == "weapon")
    |> Repo.all()
  end
end
