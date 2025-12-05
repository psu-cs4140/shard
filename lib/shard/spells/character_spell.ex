defmodule Shard.Spells.CharacterSpell do
  @moduledoc """
  The character_spell module defines the join table between characters and spells.
  This represents the spells that a character knows.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Characters.Character
  alias Shard.Spells.Spells

  schema "character_spells" do
    belongs_to :character, Character
    belongs_to :spell, Spells

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(character_spell, attrs) do
    character_spell
    |> cast(attrs, [:character_id, :spell_id])
    |> validate_required([:character_id, :spell_id])
    |> foreign_key_constraint(:character_id)
    |> foreign_key_constraint(:spell_id)
    |> unique_constraint([:character_id, :spell_id])
  end
end
