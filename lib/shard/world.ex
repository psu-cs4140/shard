defmodule Shard.World do
  @moduledoc "Domain context for Rooms and Exits."

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.World.{Room, Exit}

  ## Rooms

  def list_rooms do
    from(r in Room, order_by: [asc: r.name]) |> Repo.all()
  end

  def get_room!(id), do: Repo.get!(Room, id)

  def create_room(attrs \\ %{}) do
    %Room{} |> Room.changeset(attrs) |> Repo.insert()
  end

  def update_room(%Room{} = room, attrs) do
    room |> Room.changeset(attrs) |> Repo.update()
  end

  def delete_room(%Room{} = room), do: Repo.delete(room)

  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  ## Exits

  def list_exits do
    Repo.all(Exit)
  end

  def get_exit!(id), do: Repo.get!(Exit, id)

  def create_exit(attrs \\ %{}) do
    %Exit{} |> Exit.changeset(attrs) |> Repo.insert()
  end

  def update_exit(%Exit{} = ex, attrs) do
    ex |> Exit.changeset(attrs) |> Repo.update()
  end

  def delete_exit(%Exit{} = ex), do: Repo.delete(ex)

  def change_exit(%Exit{} = ex, attrs \\ %{}) do
    Exit.changeset(ex, attrs)
  end

  ## Game helpers

  @doc """
  Move from a room id in a direction ("n","s","e","w","up","down").
  Returns {:ok, dest_room} or {:error, :no_exit}.
  """
  def move(room_id, dir) when is_binary(dir) do
    _ = get_room!(room_id)

    case Repo.get_by(Exit, from_room_id: room_id, dir: dir) do
      %Exit{to_room_id: to_id} -> {:ok, get_room!(to_id)}
      _ -> {:error, :no_exit}
    end
  end

  ## Exit query helpers

  # all exits leaving a room (ordered for stable UI)
  def exits_from(room_id) do
    from(e in Exit, where: e.from_room_id == ^room_id, order_by: [asc: e.dir])
    |> Repo.all()
  end

  # find a specific exit by from_room and direction
  def find_exit(room_id, dir) when is_binary(dir) do
    Repo.get_by(Exit, from_room_id: room_id, dir: dir)
  end

  def find_exit(room_id, dir) when is_atom(dir) do
    find_exit(room_id, Atom.to_string(dir))
  end

  alias Shard.World.Monster

  @doc """
  Returns the list of monsters.

  ## Examples

      iex> list_monsters()
      [%Monster{}, ...]

  """
  def list_monsters do
    Repo.all(Monster)
  end

  @doc """
  Gets a single monster.

  Raises `Ecto.NoResultsError` if the Monster does not exist.

  ## Examples

      iex> get_monster!(123)
      %Monster{}

      iex> get_monster!(456)
      ** (Ecto.NoResultsError)

  """
  def get_monster!(id), do: Repo.get!(Monster, id)

  @doc """
  Creates a monster.

  ## Examples

      iex> create_monster(%{field: value})
      {:ok, %Monster{}}

      iex> create_monster(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_monster(attrs) do
    %Monster{}
    |> Monster.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a monster.

  ## Examples

      iex> update_monster(monster, %{field: new_value})
      {:ok, %Monster{}}

      iex> update_monster(monster, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_monster(%Monster{} = monster, attrs) do
    monster
    |> Monster.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a monster.

  ## Examples

      iex> delete_monster(monster)
      {:ok, %Monster{}}

      iex> delete_monster(monster)
      {:error, %Ecto.Changeset{}}

  """
  def delete_monster(%Monster{} = monster) do
    Repo.delete(monster)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking monster changes.

  ## Examples

      iex> change_monster(monster)
      %Ecto.Changeset{data: %Monster{}}

  """
  def change_monster(%Monster{} = monster, attrs \\ %{}) do
    Monster.changeset(monster, attrs)
  end
end
