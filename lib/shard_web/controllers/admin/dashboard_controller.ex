defmodule ShardWeb.Admin.DashboardController do
  use ShardWeb, :controller

  @impl true
  def index(conn, _params) do
    # Minimal placeholder; swap to `render/3` when you add templates.
    text(conn, "admin dashboard")
  end
end
