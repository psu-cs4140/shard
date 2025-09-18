defmodule ShardWeb.AdminController do
  use ShardWeb, :controller

  plug :require_admin

  def index(conn, _params) do
    render(conn, :index)
  end

  def map(conn, _params) do
    render(conn, :map)
  end

  def mud(conn, _params) do
    render(conn, :mud)
  end

  defp require_admin(conn, _params) do
    case conn.assigns.current_scope.user.admin do
      true -> conn
      _ -> 
        conn
        |> put_flash(:error, "You are not authorized to access this page.")
        |> redirect(to: ~p"/")
        |> halt()
    end
  end
end
