defmodule ShardWeb.AdminAccessTest do
  use ShardWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Shard.Repo
  alias Ecto.Changeset

  # Provided by the Phoenix auth generator in ConnCase helpers
  setup :register_and_log_in_user

  test "admin dashboard loads for admins", %{conn: conn, user: user} do
    # promote the user to admin for this request
    user = Repo.update!(Changeset.change(user, admin: true))
    conn = log_in_user(conn, user)

    conn = get(conn, ~p"/admin")
    assert html_response(conn, 200) =~ "Admin"
  end

  test "admin liveviews mount for admins", %{conn: conn, user: user} do
    user = Repo.update!(Changeset.change(user, admin: true))
    conn = log_in_user(conn, user)

    {:ok, _lv1, _html1} = live(conn, ~p"/admin/items")
    {:ok, _lv2, _html2} = live(conn, ~p"/admin/npcs")
    {:ok, _lv3, _html3} = live(conn, ~p"/admin/quests")
  end
end
