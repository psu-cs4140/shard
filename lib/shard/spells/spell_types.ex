defmodule Shard.Spells.SpellTypes do
  @moduledoc """
  The spell types module defines the schema for spell elemental types
  (e.g., fire, ice, holy, shadow, nature, arcane)
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "spell_types" do
    field :name, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(spell_type, attrs) do
    spell_type
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
