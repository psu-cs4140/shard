defmodule ShardWeb.PageController do
  use ShardWeb, :controller
  def home(conn, _params), do: html(conn, "<h1>Welcome to Phoenix Framework</h1>")
end
