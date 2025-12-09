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
  Gets a single character or returns nil if it does not exist.
  """
  def get_character(id) do
    case Repo.get(Character, id) do
      nil -> nil
      character -> Repo.preload(character, :user)
    end
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

  @doc """
  Grants a pet rock to the given character and resets its XP.
  """
  def grant_pet_rock(%Character{} = character, level \\ 1) do
    level = normalize_pet_level(level)

    update_character(character, %{
      has_pet_rock: true,
      pet_rock_level: level,
      pet_rock_xp: 0
    })
  end

  @doc """
  Grants a shroomling companion to the given character and resets its XP.
  """
  def grant_shroomling(%Character{} = character, level \\ 1) do
    level = normalize_pet_level(level)

    update_character(character, %{
      has_shroomling: true,
      shroomling_level: level,
      shroomling_xp: 0
    })
  end

  @doc """
  Grants both available pets to the given character at the provided level.
  """
  def grant_all_pets(%Character{} = character, level \\ 1) do
    level = normalize_pet_level(level)

    case grant_pet_rock(character, level) do
      {:ok, character} -> grant_shroomling(character, level)
      {:error, _} = error -> error
    end
  end

  defp normalize_pet_level(level) when is_integer(level), do: max(level, 1)
  defp normalize_pet_level(_level), do: 1

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
  Processes monster drop events from combat, handling item drops and inventory updates.
  """
  def process_monster_drop_events(events) do
    Enum.each(events, &process_single_drop_event/1)
  end

  defp process_single_drop_event(%{type: :monster_drop, character_id: character_id, item: item}) do
    # Add the dropped item to the character's inventory
    case get_character(character_id) do
      nil -> :ok
      character ->
        # This would typically call into the Items context to add the item
        # For now, we'll just log or handle it gracefully
        :ok
    end
  end

  defp process_single_drop_event(_event), do: :ok
end
