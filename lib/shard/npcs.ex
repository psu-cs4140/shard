defmodule Shard.Npcs do
  @moduledoc """
  The Npcs context.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Npcs.Npc

  @doc """
  Returns the list of npcs.

  ## Examples

      iex> list_npcs()
      [%Npc{}, ...]

  """
  def list_npcs do
    Repo.all(Npc)
  end

  @doc """
  Returns the list of npcs with preloaded associations.
  """
  def list_npcs_with_preloads do
    Repo.all(Npc)
    |> Repo.preload([:room])
  end

  @doc """
  Gets a single npc.

  Raises `Ecto.NoResultsError` if the Npc does not exist.

  ## Examples

      iex> get_npc!(123)
      %Npc{}

      iex> get_npc!(456)
      ** (Ecto.NoResultsError)

  """
  def get_npc!(id), do: Repo.get!(Npc, id)

  @doc """
  Gets a single npc with preloaded associations.
  """
  def get_npc_with_preloads!(id) do
    Repo.get!(Npc, id)
    |> Repo.preload([:room])
  end

  @doc """
  Gets a single npc by name.
  """
  def get_npc_by_name(name) do
    Repo.get_by(Npc, name: name)
  end

  @doc """
  Gets NPCs by room.
  """
  def get_npcs_by_room(room_id) do
    from(n in Npc, where: n.room_id == ^room_id and n.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets NPCs by location coordinates.
  """
  def get_npcs_by_location(x, y, z \\ 0) do
    from(n in Npc, 
      where: n.location_x == ^x and n.location_y == ^y and n.location_z == ^z and n.is_active == true)
    |> Repo.all()
  end

  @doc """
  Gets NPCs by type.
  """
  def get_npcs_by_type(npc_type) do
    from(n in Npc, where: n.npc_type == ^npc_type and n.is_active == true)
    |> Repo.all()
  end

  @doc """
  Creates a npc.

  ## Examples

      iex> create_npc(%{field: value})
      {:ok, %Npc{}}

      iex> create_npc(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_npc(attrs \\ %{}) do
    %Npc{}
    |> Npc.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a npc.

  ## Examples

      iex> update_npc(npc, %{field: new_value})
      {:ok, %Npc{}}

      iex> update_npc(npc, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_npc(%Npc{} = npc, attrs) do
    npc
    |> Npc.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a npc.

  ## Examples

      iex> delete_npc(npc)
      {:ok, %Npc{}}

      iex> delete_npc(npc)
      {:error, %Ecto.Changeset{}}

  """
  def delete_npc(%Npc{} = npc) do
    Repo.delete(npc)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking npc changes.

  ## Examples

      iex> change_npc(npc)
      %Ecto.Changeset{data: %Npc{}}

  """
  def change_npc(%Npc{} = npc, attrs \\ %{}) do
    Npc.changeset(npc, attrs)
  end

  @doc """
  Returns the list of rooms for NPC assignment.
  """
  def list_rooms do
    alias Shard.Map.Room
    Repo.all(Room)
  end
end
