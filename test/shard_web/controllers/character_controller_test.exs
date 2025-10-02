defmodule ShardWeb.CharacterControllerTest do
  use ShardWeb.ConnCase

  import Shard.UsersFixtures

  describe "character routes" do
    setup do
      user = user_fixture()
      %{user: user}
    end

    test "redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/characters")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "shows characters page when authenticated", %{conn: conn, user: user} do
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/characters")
      
      assert html_response(conn, 200) =~ "Characters"
    end

    test "shows new character page when authenticated", %{conn: conn, user: user} do
      conn = 
        conn
        |> log_in_user(user)
        |> get(~p"/characters/new")
      
      assert html_response(conn, 200) =~ "New Character"
    end
  end
end
