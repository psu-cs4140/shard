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

    test "redirects non-admin users with error message", %{conn: conn} do
      regular_user = user_fixture(%{admin: false})
      
      conn =
        conn
        |> log_in_user(regular_user)
        |> get(~p"/admin")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) == "You are not authorized to access this page."
    end

    test "redirects unauthenticated users", %{conn: conn} do
      conn = get(conn, ~p"/admin")
      
      # This will likely redirect to login page - adjust path as needed
      assert redirected_to(conn) in [~p"/users/log_in", ~p"/login", ~p"/"]
    end
  end
end
