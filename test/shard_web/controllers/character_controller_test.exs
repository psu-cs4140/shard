defmodule ShardWeb.CharacterControllerTest do
  use ShardWeb.ConnCase
  use ExUnit.Case, async: false

  import Shard.UsersFixtures
  import Ecto.Query

  describe "character routes" do
    setup do
      # Reset the test database to ensure clean state
      Ecto.Adapters.SQL.Sandbox.checkout(Shard.Repo)
      
      user = user_fixture()
      %{user: user}
    end

    test "redirects to login when not authenticated", %{conn: conn} do
      conn = get(conn, ~p"/characters")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    @tag :skip
    test "shows characters page when authenticated", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/characters")
      assert html_response(conn, 200) =~ "Characters"
    end

    @tag :skip
    test "shows new character page when authenticated", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/characters/new")
      assert html_response(conn, 200) =~ "New Character"
    end
  end
end
