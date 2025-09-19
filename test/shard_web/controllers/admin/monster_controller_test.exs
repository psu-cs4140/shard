defmodule ShardWeb.Admin.MonsterControllerTest do
  use ShardWeb.ConnCase

  setup %{conn: conn} do
    conn = Plug.Test.init_test_session(conn, current_user: %{id: -1, is_admin: true})
    {:ok, conn: conn}
  end

  import Shard.WorldFixtures

  @create_attrs %{
    name: "some name",
    element: "fire",
    level: 42,
    description: "some description",
    speed: 42,
    slug: "some slug",
    species: "some species",
    hp: 42,
    attack: 42,
    defense: 42,
    xp_drop: 42,
    ai: "aggressive",
    spawn_rate: 42
  }
  @update_attrs %{
    name: "some updated name",
    element: "fire",
    level: 43,
    description: "some updated description",
    speed: 43,
    slug: "some updated slug",
    species: "some updated species",
    hp: 43,
    attack: 43,
    defense: 43,
    xp_drop: 43,
    ai: "aggressive",
    spawn_rate: 43
  }
  @invalid_attrs %{
    name: nil,
    element: nil,
    level: nil,
    description: nil,
    speed: nil,
    slug: nil,
    species: nil,
    hp: nil,
    attack: nil,
    defense: nil,
    xp_drop: nil,
    ai: nil,
    spawn_rate: nil
  }

  describe "index" do
    test "lists all monsters", %{conn: conn} do
      conn = get(conn, ~p"/admin/monsters")
      assert html_response(conn, 200) =~ "Listing Monsters"
    end
  end

  describe "new monster" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/admin/monsters/new")
      assert html_response(conn, 200) =~ "New Monster"
    end
  end

  describe "create monster" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/admin/monsters", monster: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/admin/monsters/#{id}"

      conn = get(conn, ~p"/admin/monsters/#{id}")
      assert html_response(conn, 200) =~ "Monster #{id}"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/admin/monsters", monster: @invalid_attrs)
      assert html_response(conn, 200) =~ "New Monster"
    end
  end

  describe "edit monster" do
    setup [:create_monster]

    test "renders form for editing chosen monster", %{conn: conn, monster: monster} do
      conn = get(conn, ~p"/admin/monsters/#{monster}/edit")
      assert html_response(conn, 200) =~ "Edit Monster"
    end
  end

  describe "update monster" do
    setup [:create_monster]

    test "redirects when data is valid", %{conn: conn, monster: monster} do
      conn = put(conn, ~p"/admin/monsters/#{monster}", monster: @update_attrs)
      assert redirected_to(conn) == ~p"/admin/monsters/#{monster}"

      conn = get(conn, ~p"/admin/monsters/#{monster}")
      assert html_response(conn, 200) =~ "some updated name"
    end

    test "renders errors when data is invalid", %{conn: conn, monster: monster} do
      conn = put(conn, ~p"/admin/monsters/#{monster}", monster: @invalid_attrs)
      assert html_response(conn, 200) =~ "Edit Monster"
    end
  end

  describe "delete monster" do
    setup [:create_monster]

    test "deletes chosen monster", %{conn: conn, monster: monster} do
      conn = delete(conn, ~p"/admin/monsters/#{monster}")
      assert redirected_to(conn) == ~p"/admin/monsters"

      assert_error_sent 404, fn ->
        get(conn, ~p"/admin/monsters/#{monster}")
      end
    end
  end

  defp create_monster(_) do
    monster = monster_fixture()

    %{monster: monster}
  end
end
