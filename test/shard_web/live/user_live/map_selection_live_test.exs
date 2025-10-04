defmodule ShardWeb.MapSelectionLiveTest do
  use ShardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures
  import Shard.CharactersFixtures

  describe "Map Selection page" do
    test "renders map selection page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/maps")

      assert html =~ "Choose Your Adventure"
      assert html =~ "Tutorial Terrain"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/maps")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end
end
