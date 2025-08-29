defmodule ShardWeb.PageController do
  use ShardWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
