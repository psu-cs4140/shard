defmodule ShardWeb.UserRegistrationController do
  use ShardWeb, :controller
  alias Shard.Users

  # Handles POST /users/register from the LiveView form
  def create(conn, %{"user" => user_params}) do
    case Users.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Account created.")
        |> ShardWeb.UserAuth.log_in_user(user)

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not register. Please check the form and try again.")
        |> redirect(to: ~p"/users/register")
    end
  end
end
