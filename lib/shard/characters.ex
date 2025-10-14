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
        Shard.Items.create_tutorial_key()
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
    |> Repo.all()
  end

  @doc """
  Add experience to a character and handle automatic leveling.

  ## Examples

      iex> add_experience(character, 150)
      {:ok, %Character{level: 2, experience: 50}}
      
      iex> add_experience(character, 50)
      {:ok, %Character{level: 1, experience: 150}}
  """
  def add_experience(%Character{} = character, experience_gained) when experience_gained > 0 do
    new_experience = character.experience + experience_gained

    # Check for level ups (handle multiple level ups in case of large experience gains)
    {final_level, final_experience} = process_level_ups(character.level, new_experience)

    # Calculate stat increases for level ups
    level_difference = final_level - character.level
    stat_increases = calculate_stat_increases(level_difference)

    attrs = %{
      level: final_level,
      experience: final_experience,
      health: character.health + stat_increases.health,
      mana: character.mana + stat_increases.mana,
      strength: character.strength + stat_increases.strength,
      dexterity: character.dexterity + stat_increases.dexterity,
      intelligence: character.intelligence + stat_increases.intelligence,
      constitution: character.constitution + stat_increases.constitution
    }

    case update_character(character, attrs) do
      {:ok, updated_character} ->
        if level_difference > 0 do
          {:ok, updated_character, :level_up, level_difference}
        else
          {:ok, updated_character, :experience_gained, experience_gained}
        end

      error ->
        error
    end
  end

  def add_experience(_character, _experience_gained), do: {:error, :invalid_experience}

  defp process_level_ups(current_level, current_experience) do
    case Character.check_level_up(current_level, current_experience) do
      {true, new_level, remaining_experience} ->
        # Recursively check for more level ups
        process_level_ups(new_level, remaining_experience)

      {false, level, experience} ->
        {level, experience}
    end
  end

  defp calculate_stat_increases(level_difference) do
    %{
      health: level_difference * 10,
      mana: level_difference * 5,
      strength: level_difference * 1,
      dexterity: level_difference * 1,
      intelligence: level_difference * 1,
      constitution: level_difference * 1
    }
  end

  @doc """
  Get experience required for character's next level.
  """
  def experience_to_next_level(%Character{} = character) do
    required_for_next = Character.experience_for_level(character.level + 1)
    required_for_next - character.experience
  end

  @doc """
  Get experience progress as a percentage for current level.
  """
  def experience_progress_percentage(%Character{} = character) do
    if character.level == 1 do
      # Special case for level 1
      required_for_next = Character.experience_for_level(2)
      (character.experience / required_for_next * 100) |> Float.round(1)
    else
      required_for_current = Character.experience_for_level(character.level)
      required_for_next = Character.experience_for_level(character.level + 1)
      level_experience_range = required_for_next - required_for_current
      experience_in_current_level = character.experience - required_for_current

      (experience_in_current_level / level_experience_range * 100) |> Float.round(1)
    end
  end
end
