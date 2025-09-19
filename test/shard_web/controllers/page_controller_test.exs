defmodule ShardWeb.PageControllerTest do
  use ShardWeb.ConnCase, async: true

  test "GET / returns 200 and Phoenix landing page text", %{conn: conn} do
    html = html_response(get(conn, ~p"/"), 200)
    assert html =~ "Phoenix Framework"
  end
end
