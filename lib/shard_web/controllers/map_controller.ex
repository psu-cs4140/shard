defmodule ShardWeb.MapController do
  use ShardWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Shard.Repo
  alias Shard.World.{Room, Exit}

  def index(conn, _params) do
    # handle differing exit FK/dir field names
    fields = Exit.__schema__(:fields)
    fromf = Enum.find([:from_id, :from_room_id, :source_id, :src_id, :from], &(&1 in fields))
    tof = Enum.find([:to_id, :to_room_id, :dest_id, :destination_id, :to], &(&1 in fields))
    dirf = Enum.find([:dir, :direction], &(&1 in fields))

    rooms =
      Repo.all(
        from r in Room,
          select: %{
            id: r.id,
            slug: r.slug,
            name: r.name,
            x: r.x,
            y: r.y,
            description: r.description
          }
      )

    exits =
      Repo.all(Exit)
      |> Enum.map(fn e ->
        %{dir: Map.get(e, dirf), from_id: Map.get(e, fromf), to_id: Map.get(e, tof)}
      end)

    json(conn, %{rooms: rooms, exits: exits})
  end
end
