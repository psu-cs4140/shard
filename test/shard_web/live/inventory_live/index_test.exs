defmodule ShardWeb.InventoryLive.IndexTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  describe "Index" do
    setup %{conn: conn} do
      register_and_log_in_user(%{conn: conn})
    end

    test "renders inventory page", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/inventory")

      assert html =~ "Inventory"
    end

    test "displays basic inventory interface", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/inventory")

      # Test that the basic interface elements are present
      assert has_element?(index_live, "select[name='character_id']")
    end
  end
end
