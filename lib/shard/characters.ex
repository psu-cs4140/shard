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
end
