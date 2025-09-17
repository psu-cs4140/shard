defmodule Shard.World do
  import Ecto.Query
  alias Shard.Repo
  alias Shard.World.{Room, Exit}

  def get_room!(id), do: Repo.get!(Room, id)

  def exits_from(room_id) do
    Repo.all(from e in Exit, where: e.from_room_id == ^room_id, preload: [:to_room])
  end

  def find_exit(room_id, dir) do
    Repo.one(from e in Exit, where: e.from_room_id == ^room_id and e.dir == ^dir)
  end
end
