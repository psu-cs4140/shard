defmodule Shard.Spells.Spells do
  @moduledoc """
  The spells module defines the schema for spells
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Spells.{SpellTypes, SpellEffects}

  schema "spells" do
    field :name, :string
    field :description, :string
    field :mana_cost, :integer, default: 0
    field :damage, :integer
    field :healing, :integer
    field :level_required, :integer, default: 1

    belongs_to :spell_type, SpellTypes
    belongs_to :spell_effect, SpellEffects

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(spell, attrs) do
    spell
    |> cast(attrs, [
      :name,
      :description,
      :mana_cost,
      :damage,
      :healing,
      :level_required,
      :spell_type_id,
      :spell_effect_id
    ])
    |> validate_required([:name])
    |> validate_number(:mana_cost, greater_than_or_equal_to: 0)
    |> validate_number(:level_required, greater_than: 0, less_than_or_equal_to: 100)
    |> unique_constraint(:name)
    |> foreign_key_constraint(:spell_type_id)
    |> foreign_key_constraint(:spell_effect_id)
  end
end
