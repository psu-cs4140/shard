defmodule ShardWeb.MapController do
  use ShardWeb, :controller
  alias Shard.Repo

  def index(conn, _params) do
    rooms = Ecto.Adapters.SQL.query!(Repo, "select id, slug, name from rooms order by id").rows

    exits =
      Ecto.Adapters.SQL.query!(
        Repo,
        "select dir, from_room_id, to_room_id from exits order by id"
      ).rows

    json(conn, %{rooms: rooms, exits: exits})
  end
end
