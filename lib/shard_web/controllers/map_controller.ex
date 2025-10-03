defmodule ShardWeb.MapController do
  use ShardWeb, :controller
  alias Shard.Repo
  alias Shard.World.{Room, Exit}

  def index(conn, _params) do
    rooms =
      Repo.all(Room)
      |> Enum.map(fn r ->
        %{
          "id" => r.id,
          "name" => r.name,
          "description" => r.description,
          # IMPORTANT: your schema likely stores coords as x_coordinate / y_coordinate
          "x" => r.x_coordinate,
          "y" => r.y_coordinate,
          "slug" => r.slug
        }
      end)

    exits =
      Repo.all(Exit)
      |> Enum.map(fn e ->
        %{
          "id" => e.id,
          "dir" => e.dir,
          # IMPORTANT: choose the two that actually exist in your schema
          # If your schema is from_room_id / to_room_id:
          # "from" => e.from_room_id,
          # "to"   => e.to_room_id

          # If your schema is from_room_id / to_id:
          "from" => e.from_room_id,
          "to" => e.to_id
        }
      end)

    json(conn, %{"rooms" => rooms, "exits" => exits})
  end
end
