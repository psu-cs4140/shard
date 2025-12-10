defmodule Shard.Weapons.DamageTypes do
  @moduledoc """
  This module defines the schema for a damage_type
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "damage_types" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(damage_types, attrs) do
    damage_types
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end

  def list_damage_types do
    []
  end

  def get_damage_type_by_name(_name) do
    nil
  end

  def get_effective_damage(damage, damage_type, target_resistances) do
    multiplier = get_damage_multiplier(damage_type, target_resistances)
    damage * multiplier
  end

  def get_damage_multiplier(damage_type, target_resistances) do
    Enum.into(target_resistances, %{}) |> Kernel.get_in([damage_type]) || 1.0
  end
end
