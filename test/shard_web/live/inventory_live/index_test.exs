defmodule ShardWeb.InventoryLive.IndexTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures


  describe "Index" do
    setup do
      user = user_fixture()
      
      %{user: user}
    end

    test "renders inventory page", %{conn: conn, user: user} do
      {:ok, _index_live, html} = live(conn |> log_in_user(user), ~p"/inventory")

      assert html =~ "Inventory"
    end

    test "displays basic inventory interface", %{conn: conn, user: user} do
      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      # Test that the basic interface elements are present
      assert has_element?(index_live, "select[name='character_id']")
    end
  end
end
