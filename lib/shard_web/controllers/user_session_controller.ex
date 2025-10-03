defmodule ShardWeb.UserSessionController do
  use ShardWeb, :controller

  alias Shard.Users
  alias ShardWeb.UserAuth

  # After email confirmation, log in and land on "/"
  def create(conn, %{"_action" => "confirmed"} = params) do
    create(conn, params, "User confirmed successfully.")
  end

  # Default login entry (password or magic link below)
  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  # -------------------------
  # Magic-link login
  # -------------------------
  defp create(conn, %{"user" => %{"token" => token} = user_params}, info) do
    case Users.login_user_by_magic_link(token) do
      {:ok, {user, tokens_to_disconnect}} ->
        UserAuth.disconnect_sessions(tokens_to_disconnect)

        conn
        |> put_flash(:info, info)
        # redirects to return_to or "/"
        |> UserAuth.log_in_user(user, user_params)

      _ ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  # -------------------------
  # Email + password login
  # -------------------------
  defp create(conn, %{"user" => user_params}, info) do
    %{"email" => email, "password" => password} = user_params

    if user = Users.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, info)
      # redirects to return_to or "/"
      |> UserAuth.log_in_user(user, user_params)
    else
      # Avoid user enumeration; keep message generic.
      conn
      |> put_flash(:error, "Invalid email or password")
      |> put_flash(:email, String.slice(email, 0, 160))
      |> redirect(to: ~p"/users/log_in")
    end
  end

  # -------------------------
  # Update password (requires sudo mode)
  # -------------------------
  def update_password(conn, %{"user" => user_params} = params) do
    user = conn.assigns.current_scope.user
    true = Users.sudo_mode?(user)

    {:ok, {_user, expired_tokens}} = Users.update_user_password(user, user_params)

    # Kick old LiveViews/sessions
    UserAuth.disconnect_sessions(expired_tokens)

    # After updating password, send them back to settings
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  # -------------------------
  # Logout
  # -------------------------
  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
