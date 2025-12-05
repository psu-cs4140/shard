defmodule Shard.Spells.SpellEffects do
  @moduledoc """
  The spell effects module defines the schema for spell effects
  (e.g., damage, heal, buff, debuff, stun)
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "spell_effects" do
    field :name, :string
    field :description, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(spell_effect, attrs) do
    spell_effect
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
