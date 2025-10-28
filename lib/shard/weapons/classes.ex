defmodule Shard.Weapons.Classes do
  @moduledoc """
  This module defines the schema for a weapon class
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "weapon_classes" do
    field :name, :string
    field :damage_type_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(classes, attrs) do
    classes
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
