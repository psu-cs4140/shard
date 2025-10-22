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
end
