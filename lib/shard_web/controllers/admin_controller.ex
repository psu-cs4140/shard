defmodule ShardWeb.AdminController do
  import Plug.Conn
  import Phoenix.Controller

  def init(action), do: action

  # Simple guard: require a current_user with admin: true.
  # Replace this with your real authorization as needed.
  def call(conn, :require_admin) do
    case conn.assigns[:current_user] do
      %{admin: true} ->
        conn

      _ ->
        conn
        |> put_flash(:error, "Admin access required.")
        |> redirect(to: "/")
        |> halt()
    end
  end
end
