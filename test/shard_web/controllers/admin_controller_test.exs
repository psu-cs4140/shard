defmodule ShardWeb.AdminControllerTest do
  use ShardWeb.ConnCase

  import Shard.UsersFixtures

  describe "GET /admin" do
    test "renders admin index when user is admin", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})

      conn =
        conn
        |> log_in_user(admin_user)
        |> get(~p"/admin")

      assert html_response(conn, 200) =~ "Admin"
    end
  end
end
