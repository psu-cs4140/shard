defmodule ShardWeb.MapController do
  use ShardWeb, :controller
  alias Shard.Repo
  alias World.{Room, Exit}

  def index(conn, _params) do
    rooms =
      Repo.all(Room)
      |> Enum.map(
        &%{
          id: &1.id,
          name: &1.name,
          slug: &1.slug,
          description: &1.description,
          x: &1.x,
          y: &1.y
        }
      )

    exits =
      Repo.all(Exit)
      |> Enum.map(&%{id: &1.id, dir: &1.dir, from: &1.from_room_id, to: &1.to_room_id})

    json(conn, %{rooms: rooms, exits: exits})
  end
end
