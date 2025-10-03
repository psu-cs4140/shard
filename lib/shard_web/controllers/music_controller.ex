defmodule ShardWeb.MusicController do
  use ShardWeb, :controller
  @impl true
  def index(conn, _params), do: text(conn, "music ok")
end
