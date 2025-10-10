defmodule ShardWeb.AdminLive.UserManagementTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  alias Shard.Users

  describe "mount/3" do
    test "mounts successfully for admin user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      assert html =~ "User Management"
      assert html =~ admin_user.email
    end

    test "assigns users, first_user, and current_user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture()
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      assert view.assigns.users |> Enum.map(& &1.id) |> Enum.sort() ==
               [admin_user.id, regular_user.id] |> Enum.sort()

      assert view.assigns.current_user.id == admin_user.id
      assert view.assigns.first_user != nil
    end
  end

  describe "delete_user event" do
    test "prevents user from deleting themselves", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      result = render_click(view, "delete_user", %{"user_id" => admin_user.id})

      assert result =~ "You cannot delete your own account."
      assert Users.get_user(admin_user.id) != nil
    end

    test "prevents deleting the first user", %{conn: conn} do
      first_user = Users.get_first_user()
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      result = render_click(view, "delete_user", %{"user_id" => first_user.id})

      assert result =~ "The first user cannot be deleted."
      assert Users.get_user(first_user.id) != nil
    end

    test "successfully deletes a regular user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture()
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      result = render_click(view, "delete_user", %{"user_id" => regular_user.id})

      assert result =~ "User #{regular_user.email} has been deleted."
      assert Users.get_user(regular_user.id) == nil
    end

    test "handles delete error gracefully", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      # Try to delete a non-existent user
      result = render_click(view, "delete_user", %{"user_id" => "999999"})

      assert result =~ "Failed to delete user." or result =~ "not found"
    end
  end

  describe "toggle_admin event" do
    test "prevents admin from removing their own admin status", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      result = render_click(view, "toggle_admin", %{"user_id" => admin_user.id})

      assert result =~ "You cannot remove your own admin privileges."
      
      updated_user = Users.get_user!(admin_user.id)
      assert updated_user.admin == true
    end

    test "prevents removing admin status from the first user", %{conn: conn} do
      first_user = Users.get_first_user()
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      result = render_click(view, "toggle_admin", %{"user_id" => first_user.id})

      assert result =~ "The first user must always remain an admin."
      
      updated_first_user = Users.get_user!(first_user.id)
      assert updated_first_user.admin == true
    end

    test "grants admin privileges to regular user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      result = render_click(view, "toggle_admin", %{"user_id" => regular_user.id})

      assert result =~ "Admin privileges granted for #{regular_user.email}."
      
      updated_user = Users.get_user!(regular_user.id)
      assert updated_user.admin == true
    end

    test "revokes admin privileges from admin user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      another_admin = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      result = render_click(view, "toggle_admin", %{"user_id" => another_admin.id})

      assert result =~ "Admin privileges revoked for #{another_admin.email}."
      
      updated_user = Users.get_user!(another_admin.id)
      assert updated_user.admin == false
    end

    test "handles toggle admin error gracefully", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, view, _html} = live(conn, ~p"/admin/users")

      # Try to toggle admin for a non-existent user
      result = render_click(view, "toggle_admin", %{"user_id" => "999999"})

      assert result =~ "Failed to update user privileges." or result =~ "not found"
    end
  end

  describe "render/1" do
    test "displays user information correctly", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})
      conn = log_in_user(conn, admin_user)

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      # Check header
      assert html =~ "User Management"
      assert html =~ "Manage user accounts and administrative privileges"

      # Check user emails are displayed
      assert html =~ admin_user.email
      assert html =~ regular_user.email

      # Check admin badges
      assert html =~ "Admin"
      assert html =~ "User"

      # Check confirmation status
      assert html =~ "Confirmed"
    end

    test "shows first user badge", %{conn: conn} do
      first_user = Users.get_first_user()
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      assert html =~ "First User"
    end

    test "shows 'You' badge for current user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      assert html =~ "You"
    end

    test "shows action buttons for eligible users", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})
      conn = log_in_user(conn, admin_user)

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      # Should show buttons for regular user
      assert html =~ "Grant Admin"
      assert html =~ "Delete"

      # Should show protection message for current user
      assert html =~ "Cannot modify yourself"
    end

    test "shows protection message for first user", %{conn: conn} do
      first_user = Users.get_first_user()
      admin_user = user_fixture(%{admin: true})
      conn = log_in_user(conn, admin_user)

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      assert html =~ "Protected user"
    end

    test "shows unconfirmed badge for unconfirmed users", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      unconfirmed_user = unconfirmed_user_fixture()
      conn = log_in_user(conn, admin_user)

      {:ok, _view, html} = live(conn, ~p"/admin/users")

      assert html =~ "Unconfirmed"
    end
  end
end
