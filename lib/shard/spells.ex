defmodule Shard.Spells do
  @moduledoc """
  The Spells context. Contains spell-related game logic.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Spells.{Spells, SpellTypes, SpellEffects, CharacterSpell}

  # Spell Type functions

  @doc """
  Lists all spell types.
  """
  def list_spell_types do
    Repo.all(SpellTypes)
  end

  @doc """
  Gets a single spell type.
  """
  def get_spell_type!(id), do: Repo.get!(SpellTypes, id)

  @doc """
  Creates a spell type.
  """
  def create_spell_type(attrs \\ %{}) do
    %SpellTypes{}
    |> SpellTypes.changeset(attrs)
    |> Repo.insert()
  end

  # Spell Effect functions

  @doc """
  Lists all spell effects.
  """
  def list_spell_effects do
    Repo.all(SpellEffects)
  end

  @doc """
  Gets a single spell effect.
  """
  def get_spell_effect!(id), do: Repo.get!(SpellEffects, id)

  @doc """
  Creates a spell effect.
  """
  def create_spell_effect(attrs \\ %{}) do
    %SpellEffects{}
    |> SpellEffects.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a spell effect.
  """
  def update_spell_effect(%SpellEffects{} = spell_effect, attrs) do
    spell_effect
    |> SpellEffects.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a spell effect.
  """
  def delete_spell_effect(%SpellEffects{} = spell_effect) do
    Repo.delete(spell_effect)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking spell effect changes.
  """
  def change_spell_effect(%SpellEffects{} = spell_effect, attrs \\ %{}) do
    SpellEffects.changeset(spell_effect, attrs)
  end

  # Spell functions

  @doc """
  Lists all spells.
  """
  def list_spells do
    Repo.all(Spells)
  end

  @doc """
  Gets a single spell.
  """
  def get_spell!(id) do
    Spells
    |> where([s], s.id == ^id)
    |> Repo.one()
  end

  @doc """
  Gets a spell by name.
  """
  def get_spell_by_name(name) do
    Spells
    |> where([s], s.name == ^name)
    |> Repo.one()
  end

  @doc """
  Lists spells by type.
  """
  def list_spells_by_type(type_id) do
    Spells
    |> where([s], s.spell_type_id == ^type_id)
    |> Repo.all()
  end

  @doc """
  Lists spells by effect.
  """
  def list_spells_by_effect(effect_id) do
    Spells
    |> where([s], s.spell_effect_id == ^effect_id)
    |> Repo.all()
  end

  @doc """
  Creates a spell.
  """
  def create_spell(attrs \\ %{}) do
    %Spells{}
    |> Spells.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a spell.
  """
  def update_spell(%Spells{} = spell, attrs) do
    spell
    |> Spells.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a spell.
  """
  def delete_spell(%Spells{} = spell) do
    Repo.delete(spell)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking spell changes.
  """
  def change_spell(%Spells{} = spell, attrs \\ %{}) do
    Spells.changeset(spell, attrs)
  end

  # Character Spell functions

  @doc """
  Lists all spells known by a character.
  """
  def list_character_spells(character_id) do
    CharacterSpell
    |> where([cs], cs.character_id == ^character_id)
    |> join(:inner, [cs], s in Spells, on: cs.spell_id == s.id)
    |> join(:left, [cs, s], st in SpellTypes, on: s.spell_type_id == st.id)
    |> join(:left, [cs, s, st], se in SpellEffects, on: s.spell_effect_id == se.id)
    |> select([cs, s, st, se], %{
      id: s.id,
      name: s.name,
      description: s.description,
      mana_cost: s.mana_cost,
      damage: s.damage,
      healing: s.healing,
      level_required: s.level_required,
      spell_type: st.name,
      spell_effect: se.name
    })
    |> Repo.all()
  end

  @doc """
  Adds a spell to a character's known spells.
  """
  def add_spell_to_character(character_id, spell_id) do
    %CharacterSpell{}
    |> CharacterSpell.changeset(%{character_id: character_id, spell_id: spell_id})
    |> Repo.insert()
  end

  @doc """
  Removes a spell from a character's known spells.
  """
  def remove_spell_from_character(character_id, spell_id) do
    CharacterSpell
    |> where([cs], cs.character_id == ^character_id and cs.spell_id == ^spell_id)
    |> Repo.delete_all()
  end

  @doc """
  Checks if a character knows a specific spell.
  """
  def character_knows_spell?(character_id, spell_id) do
    CharacterSpell
    |> where([cs], cs.character_id == ^character_id and cs.spell_id == ^spell_id)
    |> Repo.exists?()
  end

  @doc """
  Casts a spell by name for a character.
  Returns {:ok, spell_result} or {:error, reason}
  """
  def cast_spell(character_id, spell_name, target_id \\ nil) do
    with {:ok, spell} <- get_spell_by_name_for_character(character_id, spell_name),
         {:ok, character} <- get_character(character_id),
         :ok <- validate_spell_cast(character, spell) do
      execute_spell(character, spell, target_id)
    end
  end

  defp get_spell_by_name_for_character(character_id, spell_name) do
    spell =
      Spells
      |> join(:inner, [s], cs in CharacterSpell, on: cs.spell_id == s.id)
      |> where([s, cs], cs.character_id == ^character_id)
      |> where([s], fragment("LOWER(?) = LOWER(?)", s.name, ^spell_name))
      |> preload([:spell_type, :spell_effect])
      |> Repo.one()

    case spell do
      nil -> {:error, :spell_not_known}
      spell -> {:ok, spell}
    end
  end

  defp get_character(character_id) do
    case Repo.get(Shard.Characters.Character, character_id) do
      nil -> {:error, :character_not_found}
      character -> {:ok, character}
    end
  end

  defp validate_spell_cast(character, spell) do
    cond do
      character.mana < spell.mana_cost ->
        {:error, :insufficient_mana}

      character.level < spell.level_required ->
        {:error, :level_too_low}

      true ->
        :ok
    end
  end

  defp execute_spell(character, spell, target_id) do
    # Deduct mana cost
    new_mana = max(0, character.mana - spell.mana_cost)

    {:ok, updated_character} =
      character
      |> Shard.Characters.Character.changeset(%{mana: new_mana})
      |> Repo.update()

    # Build spell result based on spell effect
    spell_result = %{
      caster: character,
      spell: spell,
      target_id: target_id,
      damage: spell.damage,
      healing: spell.healing,
      mana_used: spell.mana_cost,
      effect_type: spell.spell_effect && spell.spell_effect.name
    }

    {:ok, spell_result}
  end
end
