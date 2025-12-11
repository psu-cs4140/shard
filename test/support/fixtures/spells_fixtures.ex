defmodule Shard.SpellsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Spells` context.
  """

  alias Shard.Spells

  def valid_spell_type_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Magic",
      description: "A test magic type for testing purposes"
    })
  end

  def spell_type_fixture(attrs \\ %{}) do
    {:ok, spell_type} =
      attrs
      |> valid_spell_type_attributes()
      |> Spells.create_spell_type()

    spell_type
  end

  def valid_spell_effect_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: "Test Effect",
      description: "A test spell effect for testing purposes"
    })
  end

  def spell_effect_fixture(attrs \\ %{}) do
    {:ok, spell_effect} =
      attrs
      |> valid_spell_effect_attributes()
      |> Spells.create_spell_effect()

    spell_effect
  end

  def valid_spell_attributes(attrs \\ %{}) do
    spell_type = spell_type_fixture()
    spell_effect = spell_effect_fixture()

    Enum.into(attrs, %{
      name: "Test Spell",
      description: "A test spell for testing purposes",
      mana_cost: 25,
      damage: 50,
      level_required: 1,
      spell_type_id: spell_type.id,
      spell_effect_id: spell_effect.id
    })
  end

  def spell_fixture(attrs \\ %{}) do
    {:ok, spell} =
      attrs
      |> valid_spell_attributes()
      |> Spells.create_spell()

    spell
  end
end
