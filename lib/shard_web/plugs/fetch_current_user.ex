defmodule ShardWeb.Plugs.FetchCurrentUser do
  import Plug.Conn
  def init(opts), do: opts
  def call(conn, _opts) do
    user = get_session(conn, :current_user)
    assign(conn, :current_user, user)
  end
end
