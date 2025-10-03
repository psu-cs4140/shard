defmodule ShardWeb.PageController do
  use ShardWeb, :controller
  alias Shard.Media

  def home(conn, _params) do
    render(conn, :home)
  end

  def music(conn, _params) do
    tracks = Media.list_music_tracks()
    render(conn, :music, tracks: tracks)
  end
end
