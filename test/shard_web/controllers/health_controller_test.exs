defmodule ShardWeb.HealthControllerTest do
  use ShardWeb.ConnCase, async: true

  test "GET /health returns ok", %{conn: conn} do
    conn = get(conn, ~p"/health")
    assert conn.status == 200
    assert conn.resp_body == "ok"
  end
end
