defmodule ShardWeb.AdminLive.UserManagementTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  alias Shard.Users

  describe "mount" do
    test "loads users and assigns current user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})

      {:ok, _view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      assert html =~ admin_user.email
      assert html =~ regular_user.email
      assert html =~ "User Management"
    end

    test "shows first user badge for first user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      first_user = Users.get_first_user()

      {:ok, _view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      if first_user do
        assert html =~ "First User"
      end
    end
  end

  describe "delete_user event" do
    test "prevents user from deleting themselves", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      result = render_click(view, "delete_user", %{"user_id" => admin_user.id})

      assert result =~ "You cannot delete your own account."
      assert Users.get_user(admin_user.id) # User still exists
    end

    test "prevents deleting the first user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      first_user = Users.get_first_user()

      # Skip test if no first user exists
      if first_user do
        {:ok, view, _html} =
          conn
          |> log_in_user(admin_user)
          |> live(~p"/admin/users")

        result = render_click(view, "delete_user", %{"user_id" => first_user.id})

        assert result =~ "The first user cannot be deleted."
        assert Users.get_user(first_user.id) # User still exists
      end
    end

    test "successfully deletes a regular user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      result = render_click(view, "delete_user", %{"user_id" => regular_user.id})

      assert result =~ "User #{regular_user.email} has been deleted."
      assert is_nil(Users.get_user(regular_user.id))
    end

    test "handles delete error gracefully", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      # Try to delete non-existent user
      result = render_click(view, "delete_user", %{"user_id" => "999999"})

      assert result =~ "Failed to delete user." or result =~ "not found"
    end
  end

  describe "toggle_admin event" do
    test "prevents admin from removing their own admin status", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      result = render_click(view, "toggle_admin", %{"user_id" => admin_user.id})

      assert result =~ "You cannot remove your own admin privileges."
      
      # Verify admin status unchanged
      updated_user = Users.get_user!(admin_user.id)
      assert updated_user.admin == true
    end

    test "prevents removing admin status from first user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      first_user = Users.get_first_user()

      # Skip test if no first user exists or first user is not admin
      if first_user && first_user.admin do
        {:ok, view, _html} =
          conn
          |> log_in_user(admin_user)
          |> live(~p"/admin/users")

        result = render_click(view, "toggle_admin", %{"user_id" => first_user.id})

        assert result =~ "The first user must always remain an admin."
        
        # Verify admin status unchanged
        updated_user = Users.get_user!(first_user.id)
        assert updated_user.admin == true
      end
    end

    test "successfully grants admin privileges to regular user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      result = render_click(view, "toggle_admin", %{"user_id" => regular_user.id})

      assert result =~ "Admin privileges granted for #{regular_user.email}."
      
      # Verify admin status changed
      updated_user = Users.get_user!(regular_user.id)
      assert updated_user.admin == true
    end

    test "successfully revokes admin privileges from admin user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      another_admin = user_fixture(%{admin: true})

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      result = render_click(view, "toggle_admin", %{"user_id" => another_admin.id})

      assert result =~ "Admin privileges revoked for #{another_admin.email}."
      
      # Verify admin status changed
      updated_user = Users.get_user!(another_admin.id)
      assert updated_user.admin == false
    end

    test "handles toggle admin error gracefully", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      # Try to toggle admin for non-existent user
      result = render_click(view, "toggle_admin", %{"user_id" => "999999"})

      assert result =~ "Failed to update user privileges." or result =~ "not found"
    end
  end

  describe "render" do
    test "displays user information correctly", %{conn: conn} do
      admin_user = user_fixture(%{admin: true, confirmed_at: DateTime.utc_now()})
      regular_user = user_fixture(%{admin: false, confirmed_at: nil})

      {:ok, _view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      # Check headers
      assert html =~ "User Management"
      assert html =~ "Manage user accounts and administrative privileges"

      # Check table headers
      assert html =~ "Email"
      assert html =~ "Admin Status"
      assert html =~ "Confirmed"
      assert html =~ "Actions"

      # Check user data
      assert html =~ admin_user.email
      assert html =~ regular_user.email

      # Check admin badges
      assert html =~ "Admin"
      assert html =~ "User"

      # Check confirmation status
      assert html =~ "Confirmed"
      assert html =~ "Unconfirmed"

      # Check "You" badge for current user
      assert html =~ "You"
    end

    test "shows appropriate action buttons for different user types", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})

      {:ok, _view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      # Current user should show "Cannot modify yourself"
      assert html =~ "Cannot modify yourself"

      # Regular user should show action buttons
      assert html =~ "Grant Admin"
      assert html =~ "Delete"
    end

    test "shows protected user message for first user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      first_user = Users.get_first_user()

      if first_user && first_user.id != admin_user.id do
        {:ok, _view, html} =
          conn
          |> log_in_user(admin_user)
          |> live(~p"/admin/users")

        assert html =~ "Protected user"
      end
    end

    test "shows confirmation dialogs for destructive actions", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})

      {:ok, _view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/users")

      # Check for confirmation dialog attributes
      assert html =~ "data-confirm"
      assert html =~ "Are you sure you want to delete"
      assert html =~ "This action cannot be undone"
    end
  end
end
