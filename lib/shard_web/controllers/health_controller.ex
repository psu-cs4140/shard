defmodule ShardWeb.HealthController do
  use ShardWeb, :controller
  def show(conn, _params), do: text(conn, "ok")
end
