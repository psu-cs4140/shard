defmodule ShardWeb.Plugs.RequireAdmin do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    conn = fetch_query_params(conn)
    dev_override? = conn.params["as_admin"] in ["1", 1, true, "true"]
    user = conn.assigns[:current_user]

    cond do
      user && Map.get(user, :is_admin) ->
        conn

      dev_override? and Mix.env() in [:dev, :test] ->
        conn

      true ->
        conn
        |> put_flash(:error, "Admins only.")
        |> redirect(to: "/")
        |> halt()
    end
  end
end
