defmodule Shard.Characters do
  @moduledoc """
  The Characters context.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Characters.Character

  @doc """
  Returns the list of characters.

  ## Examples

      iex> list_characters()
      [%Character{}, ...]

  """
  def list_characters do
    Repo.all(Character)
    |> Repo.preload(:user)
  end

  @doc """
  Gets a single character.

  Raises `Ecto.NoResultsError` if the Character does not exist.

  ## Examples

      iex> get_character!(123)
      %Character{}

      iex> get_character!(456)
      ** (Ecto.NoResultsError)

  """
  def get_character!(id) do
    Repo.get!(Character, id)
    |> Repo.preload(:user)
  end

  @doc """
  Creates a character.

  ## Examples

      iex> create_character(%{field: value})
      {:ok, %Character{}}

      iex> create_character(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_character(attrs \\ %{}) do
    case %Character{}
         |> Character.changeset(attrs)
         |> Repo.insert() do
      {:ok, character} ->
        # Create tutorial key when character is created
        Shard.Items.GameFeatures.create_tutorial_key()

        # Check and award "Create First Character" achievement
        check_and_award_first_character_achievement(character)

        {:ok, character}

      error ->
        error
    end
  end

  @doc """
  Updates a character.

  ## Examples

      iex> update_character(character, %{field: new_value})
      {:ok, %Character{}}

      iex> update_character(character, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_character(%Character{} = character, attrs) do
    character
    |> Character.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a character.

  ## Examples

      iex> delete_character(character)
      {:ok, %Character{}}

      iex> delete_character(character)
      {:error, %Ecto.Changeset{}}

  """
  def delete_character(%Character{} = character) do
    Repo.delete(character)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking character changes.

  ## Examples

      iex> change_character(character)
      %Ecto.Changeset{data: %Character{}}

  """
  def change_character(%Character{} = character, attrs \\ %{}) do
    Character.changeset(character, attrs)
  end

  @doc """
  Gets characters by user.
  """
  def get_characters_by_user(user_id) do
    from(c in Character, where: c.user_id == ^user_id)
    |> Ecto.Query.order_by([c], asc: c.inserted_at, asc: c.id)
    |> Repo.all()
  end

  @doc """
  Gets a character by name (case-insensitive).
  """
  def get_character_by_name(name) do
    from(c in Character, where: ilike(c.name, ^name))
    |> Repo.one()
  end

  @doc """
  Gets all active characters (for multiplayer features like poke command).
  """
  def list_active_characters do
    from(c in Character, where: c.is_active == true)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  # Private function to check and award the "Create First Character" achievement
  defp check_and_award_first_character_achievement(%Character{user_id: user_id}) do
    with {:ok, user_id} <- validate_user_id(user_id),
         {:ok, user} <- get_user_for_achievement(user_id),
         {:ok, achievement} <- get_first_character_achievement(),
         false <- Shard.Achievements.has_achievement?(user, achievement) do
      award_achievement_safely(user, achievement)
    else
      _ -> :ok
    end
  end

  defp validate_user_id(nil), do: {:error, :no_user_id}
  defp validate_user_id(user_id), do: {:ok, user_id}

  defp get_user_for_achievement(user_id) do
    case Shard.Repo.get(Shard.Users.User, user_id) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp get_first_character_achievement do
    case Shard.Repo.get_by(Shard.Achievements.Achievement, name: "Create First Character") do
      nil -> {:error, :achievement_not_found}
      achievement -> {:ok, achievement}
    end
  end

  defp award_achievement_safely(user, achievement) do
    case Shard.Achievements.award_achievement(user, achievement) do
      {:ok, _user_achievement} -> :ok
      # Silently handle errors to not break character creation
      {:error, _changeset} -> :ok
    end
  end

  @doc """
  Adds experience to a character.
  """
  def add_experience(%Character{} = character, amount) when amount > 0 do
    new_experience = character.experience + amount
    update_character(character, %{experience: new_experience})
  end

  @doc """
  Gets a character with their skills preloaded.
  """
  def get_character_with_skills!(id) do
    Repo.get!(Character, id)
    |> Repo.preload([:character_skills, :skills])
  end

  @doc """
  Calculates effective stats for a character including skill bonuses.
  """
  def get_effective_stats(%Character{} = character) do
    character = Repo.preload(character, [character_skills: :skill_node])
    
    base_stats = %{
      health: character.health,
      mana: character.mana,
      strength: character.strength,
      dexterity: character.dexterity,
      intelligence: character.intelligence,
      constitution: character.constitution
    }

    # Apply skill bonuses
    Enum.reduce(character.character_skills, base_stats, fn character_skill, stats ->
      apply_skill_effects(stats, character_skill.skill_node.effects)
    end)
  end

  defp apply_skill_effects(stats, effects) when is_map(effects) do
    Enum.reduce(effects, stats, fn {effect_key, effect_value}, acc_stats ->
      case effect_key do
        "health_bonus" -> Map.update!(acc_stats, :health, &(&1 + effect_value))
        "mana_bonus" -> Map.update!(acc_stats, :mana, &(&1 + effect_value))
        "damage_bonus" -> Map.put(acc_stats, :damage_multiplier, Map.get(acc_stats, :damage_multiplier, 1.0) + effect_value)
        "defense_penalty" -> Map.put(acc_stats, :defense_multiplier, Map.get(acc_stats, :defense_multiplier, 1.0) - effect_value)
        "debuff_resistance" -> Map.put(acc_stats, :debuff_resistance, effect_value)
        _ -> acc_stats
      end
    end)
  end

  defp apply_skill_effects(stats, _), do: stats
end
