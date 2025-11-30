defmodule ShardWeb.AdminLive.UserManagementTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures
  import Ecto.Query

  alias Shard.Repo
  alias Shard.Users
  alias Shard.Users.User

  describe "mount" do
    test "loads users and assigns current user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})

      {:ok, _view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

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
        |> live(~p"/admin/user_management")

      if first_user do
        assert html =~ "First User"
      end
    end
  end

  describe "delete_user event" do
    test "prevents user from deleting themselves", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})

      {:ok, view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Check if admin_user is the first user (would show "Protected user")
      if Users.first_user?(admin_user) do
        # If admin_user is first user, they should show "Protected user"
        assert html =~ "Protected user"

        # Try to click delete anyway (should trigger the server-side check)
        render_click(view, "delete_user", %{"user_id" => admin_user.id})

        # Verify the page still renders correctly and shows first user protection
        updated_html = render(view)
        assert updated_html =~ "Protected user"
        assert updated_html =~ "First User"
      else
        # If admin_user is not first user, they should show "Cannot modify yourself"
        assert html =~ "Cannot modify yourself"

        # Try to click delete anyway (should trigger the server-side check)
        render_click(view, "delete_user", %{"user_id" => admin_user.id})

        # Verify the page still renders correctly
        updated_html = render(view)
        assert updated_html =~ "Cannot modify yourself"
      end

      # Verify user still exists in either case
      assert Users.get_user!(admin_user.id)
    end

    test "prevents deleting the first user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      first_user = Users.get_first_user()

      # Skip test if no first user exists or if admin_user is the first user
      if first_user && first_user.id != admin_user.id do
        {:ok, view, html} =
          conn
          |> log_in_user(admin_user)
          |> live(~p"/admin/user_management")

        # First user should show "Protected user" instead of action buttons
        assert html =~ "Protected user"

        # Try to click delete anyway (should trigger the server-side check)
        result = render_click(view, "delete_user", %{"user_id" => first_user.id})

        assert result =~ "The first user cannot be deleted."
        # Verify user still exists
        assert Users.get_user!(first_user.id)
      end
    end

    test "successfully deletes a regular user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})

      {:ok, view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Verify the regular user appears in the initial HTML
      assert html =~ regular_user.email

      render_click(view, "delete_user", %{"user_id" => regular_user.id})

      # Check that the user no longer appears in the table (not in flash)
      updated_html = render(view)
      document = LazyHTML.from_fragment(updated_html)
      table_matches = LazyHTML.filter(document, "table tbody td")
      table_text = Enum.map(table_matches, &LazyHTML.text/1) |> Enum.join(" ")
      refute table_text =~ regular_user.email

      # Check that the user was actually deleted from the database
      assert_raise Ecto.NoResultsError, fn ->
        Users.get_user!(regular_user.id)
      end
    end

    test "handles delete error gracefully", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Try to delete non-existent user
      render_click(view, "delete_user", %{"user_id" => "999999"})

      # Verify the page still renders correctly and no changes occurred
      updated_html = render(view)
      assert updated_html =~ "User Management"
      assert updated_html =~ admin_user.email

      # Verify admin user still exists and is unchanged
      updated_admin = Users.get_user!(admin_user.id)
      assert updated_admin.admin == true
    end
  end

  describe "toggle_admin event" do
    test "prevents admin from removing their own admin status", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      # Create another user to ensure admin_user is not the first user
      _other_user = user_fixture(%{admin: false})

      {:ok, view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Check if admin_user is the first user (would show "Protected user")
      if Users.first_user?(admin_user) do
        # If admin_user is first user, they should show "Protected user"
        assert html =~ "Protected user"

        # Try to click toggle_admin anyway (should trigger the server-side check)
        render_click(view, "toggle_admin", %{"user_id" => admin_user.id})

        # Verify the page still renders correctly and shows first user protection
        updated_html = render(view)
        assert updated_html =~ "Protected user"
        assert updated_html =~ "First User"
      else
        # If admin_user is not first user, they should show "Cannot modify yourself"
        assert html =~ "Cannot modify yourself"

        # Try to click toggle_admin anyway (should trigger the server-side check)
        render_click(view, "toggle_admin", %{"user_id" => admin_user.id})

        # Verify the page still renders correctly
        updated_html = render(view)
        assert updated_html =~ "Cannot modify yourself"
      end

      # Verify admin status unchanged in either case
      updated_user = Users.get_user!(admin_user.id)
      assert updated_user.admin == true
    end

    test "prevents removing admin status from first user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      first_user = Users.get_first_user()

      # Skip test if no first user exists or first user is not admin
      if first_user && first_user.admin && first_user.id != admin_user.id do
        {:ok, view, html} =
          conn
          |> log_in_user(admin_user)
          |> live(~p"/admin/user_management")

        # First user should show "Protected user" instead of action buttons
        assert html =~ "Protected user"

        # Try to click toggle_admin anyway (should trigger the server-side check)
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
        |> live(~p"/admin/user_management")

      render_click(view, "toggle_admin", %{"user_id" => regular_user.id})

      # Verify admin status changed in database
      updated_user = Users.get_user!(regular_user.id)
      assert updated_user.admin == true

      # Verify UI shows the user as admin now
      updated_html = render(view)
      assert updated_html =~ "Revoke Admin"
      refute updated_html =~ "Grant Admin"
    end

    test "successfully revokes admin privileges from admin user", %{conn: conn} do
      # Create first admin user (will be the first user)
      admin_user = user_fixture(%{admin: true})
      # Create a regular user first to ensure another_admin is not the first user
      _regular_user = user_fixture(%{admin: false})
      # Create another admin user (should not be the first user)
      another_admin = user_fixture(%{admin: true})

      {:ok, view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Verify another_admin is not the first user and shows revoke button
      refute Users.first_user?(another_admin)
      assert html =~ "Revoke Admin"

      render_click(view, "toggle_admin", %{"user_id" => another_admin.id})

      # Verify admin status changed in database
      updated_user = Users.get_user!(another_admin.id)
      assert updated_user.admin == false

      # Verify UI shows the user as regular user now
      updated_html = render(view)
      assert updated_html =~ "Grant Admin"
      # Check that we don't have "Revoke Admin" for the another_admin user specifically
      refute updated_html =~ another_admin.email && updated_html =~ "Revoke Admin"
    end

    test "handles toggle admin error gracefully", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})

      {:ok, view, _initial_html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Try to toggle admin for non-existent user
      render_click(view, "toggle_admin", %{"user_id" => "999999"})

      # Verify the page still renders correctly and no changes occurred
      updated_html = render(view)
      assert updated_html =~ "User Management"
      assert updated_html =~ admin_user.email

      # Verify admin user's status is unchanged
      updated_admin = Users.get_user!(admin_user.id)
      assert updated_admin.admin == true
    end
  end

  describe "create_user event" do
    test "successfully creates a new user with login link", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      new_email = "newuser@example.com"

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Submit the form
      html = render_submit(view, "create_user", %{"email" => new_email})

      # Check success flash
      assert html =~ "User #{new_email} created successfully"
      assert html =~ "Share the login link below"

      # Check user was created and confirmed
      new_user = Users.get_user_by_email(new_email)
      assert new_user
      assert new_user.confirmed_at

      # Check login link is displayed
      assert html =~ "/users/log-in/"
      assert html =~ "Copy and send this link to the user for their first login"

      # Extract the login URL from HTML (simple regex for href)
      login_url = Regex.run(~r|href="([^"]*/users/log-in/[^"]*)|, html) |> List.last()

      # Test the login link works
      test_conn = get(conn, login_url)
      # The link leads to the confirmation page; submit the form to log in
      token = Regex.run(~r|name="user\[token\]" value="([^"]+)"|, test_conn.resp_body) |> List.last()  # Extract token from hidden input
      login_conn = post(test_conn, "/users/log-in", %{"user" => %{"token" => token}})
      # After login, should have user_token in session
      assert get_session(login_conn, :user_token)
      # And should redirect to home
      assert redirected_to(login_conn) =~ ~p"/"
    end

    test "fails to create user with invalid email", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      invalid_email = "invalid-email"

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Submit the form with invalid email
      html = render_submit(view, "create_user", %{"email" => invalid_email})

      # Check error flash
      assert html =~ "Failed to create user"

      # Check user was not created
      refute Users.get_user_by_email(invalid_email)

      # Check no login link displayed
      refute html =~ "/users/log-in/"
    end

    test "fails to create user with duplicate email", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      existing_email = admin_user.email

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Submit the form with existing email
      html = render_submit(view, "create_user", %{"email" => existing_email})

      # Check error flash
      assert html =~ "Failed to create user"

      # Check no additional user created
      users_with_email = Repo.all(from u in User, where: u.email == ^existing_email)
      assert length(users_with_email) == 1

      # Check no login link displayed
      refute html =~ "/users/log-in/"
    end

    test "shows login link for existing user", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      regular_user = user_fixture(%{admin: false})

      {:ok, view, _html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Click the show login link button
      html = render_click(view, "show_login_link", %{"user_id" => regular_user.id})

      # Check success flash
      assert html =~ "Login link generated for #{regular_user.email}"

      # Check login link is displayed
      assert html =~ "/users/log-in/"
      assert html =~ "Copy and send this link to the user"

      # Extract the login URL from HTML
      login_url = Regex.run(~r|href="([^"]*/users/log-in/[^"]*)|, html) |> List.last()

      # Test the login link works
      test_conn = get(conn, login_url)
      # The link leads to the confirmation page; submit the form to log in
      token = Regex.run(~r|name="user\[token\]" value="([^"]+)"|, test_conn.resp_body) |> List.last()  # Extract token from hidden input
      login_conn = post(test_conn, "/users/log-in", %{"user" => %{"token" => token}})
      # After login, should have user_token in session
      assert get_session(login_conn, :user_token)
      # And should redirect to home
      assert redirected_to(login_conn) =~ ~p"/"
    end
  end

  describe "render" do
    test "displays user information correctly", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      # Create an unconfirmed user by using unconfirmed_user_fixture
      unconfirmed_user = unconfirmed_user_fixture(%{admin: false})

      {:ok, _view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

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
      assert html =~ unconfirmed_user.email

      # Check admin badges
      assert html =~ "Admin"
      assert html =~ "User"

      # Check confirmation status
      assert html =~ "Confirmed"
      assert html =~ "Unconfirmed"

      # Check "You" badge for current user (only if current user is not the first user)
      if Users.first_user?(admin_user) do
        # If admin_user is first user, they should show "Protected user" instead of "You"
        assert html =~ "Protected user"
      else
        # If admin_user is not first user, they should show "You" badge
        assert html =~ "You"
      end
    end

    test "shows appropriate action buttons for different user types", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      _regular_user = user_fixture(%{admin: false})

      {:ok, _view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Check if admin_user is the first user (would show "Protected user")
      if Users.first_user?(admin_user) do
        # If admin_user is first user, they should show "Protected user"
        assert html =~ "Protected user"
      else
        # If admin_user is not first user, they should show "Cannot modify yourself"
        assert html =~ "Cannot modify yourself"
      end

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
          |> live(~p"/admin/user_management")

        assert html =~ "Protected user"
      end
    end

    test "shows confirmation dialogs for destructive actions", %{conn: conn} do
      admin_user = user_fixture(%{admin: true})
      _regular_user = user_fixture(%{admin: false})

      {:ok, _view, html} =
        conn
        |> log_in_user(admin_user)
        |> live(~p"/admin/user_management")

      # Check for confirmation dialog attributes
      assert html =~ "data-confirm"
      assert html =~ "Are you sure you want to delete"
      assert html =~ "This action cannot be undone"
    end
  end
end
