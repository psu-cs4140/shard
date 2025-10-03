defmodule Shard.World do
  @moduledoc "Domain context for Rooms, Exits, Monsters."

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.World.{Room, Exit, Monster}

  ## Rooms
  def list_rooms, do: from(r in Room, order_by: [asc: r.name]) |> Repo.all()
  def get_room!(id), do: Repo.get!(Room, id)
  def create_room(attrs \\ %{}), do: %Room{} |> Room.changeset(attrs) |> Repo.insert()
  def update_room(%Room{} = room, attrs), do: room |> Room.changeset(attrs) |> Repo.update()
  def delete_room(%Room{} = room), do: Repo.delete(room)
  def change_room(%Room{} = room, attrs \\ %{}), do: Room.changeset(room, attrs)

  ## Exits
  def list_exits, do: Repo.all(Exit)
  def get_exit!(id), do: Repo.get!(Exit, id)
  def create_exit(attrs \\ %{}), do: %Exit{} |> Exit.changeset(attrs) |> Repo.insert()
  def update_exit(%Exit{} = ex, attrs), do: ex |> Exit.changeset(attrs) |> Repo.update()
  def delete_exit(%Exit{} = ex), do: Repo.delete(ex)
  def change_exit(%Exit{} = ex, attrs \\ %{}), do: Exit.changeset(ex, attrs)

  ## Move helpers
  @doc """
  Move from room_id in direction "n","s","e","w","up","down".
  Returns {:ok, dest_room} or {:error, :no_exit}.
  """
  def move(room_id, dir) when is_binary(dir) do
    _ = get_room!(room_id)

    case Repo.get_by(Exit, from_room_id: room_id, dir: dir) do
      %Exit{to_id: to_id} -> {:ok, get_room!(to_id)}
      _ -> {:error, :no_exit}
    end
  end

  def exits_from(room_id) do
    from(e in Exit, where: e.from_room_id == ^room_id, order_by: [asc: e.dir])
    |> Repo.all()
  end

  def find_exit(room_id, dir) when is_binary(dir),
    do: Repo.get_by(Exit, from_room_id: room_id, dir: dir)

  def find_exit(room_id, dir) when is_atom(dir),
    do: find_exit(room_id, Atom.to_string(dir))

  ## Monsters
  def list_monsters, do: Repo.all(Monster)
  def get_monster!(id), do: Repo.get!(Monster, id)
  def create_monster(attrs), do: %Monster{} |> Monster.changeset(attrs) |> Repo.insert()
  def update_monster(%Monster{} = m, attrs), do: m |> Monster.changeset(attrs) |> Repo.update()
  def delete_monster(%Monster{} = m), do: Repo.delete(m)
  def change_monster(%Monster{} = m, attrs \\ %{}), do: Monster.changeset(m, attrs)
end
