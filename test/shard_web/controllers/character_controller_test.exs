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

    test "shows characters page when authenticated", %{conn: conn, user: user} do
      # Debug: Check if zones table exists and what columns it has
      case Ecto.Adapters.SQL.query(Shard.Repo, "SELECT column_name FROM information_schema.columns WHERE table_name = 'zones'", []) do
        {:ok, %{rows: rows}} ->
          columns = Enum.map(rows, fn [col] -> col end)
          IO.puts("Zones table columns: #{inspect(columns)}")
        {:error, error} ->
          IO.puts("Error checking zones table: #{inspect(error)}")
      end

      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/characters")
      assert html_response(conn, 200) =~ "Characters"
    end

    test "shows new character page when authenticated", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      conn = get(conn, ~p"/characters/new")
      assert html_response(conn, 200) =~ "New Character"
    end
  end
end
