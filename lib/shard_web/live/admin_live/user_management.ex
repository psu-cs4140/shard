defmodule ShardWeb.AdminLive.UserManagement do
  use ShardWeb, :live_view

  alias Shard.Users
  alias Shard.Repo

  @impl true
  def mount(_params, _session, socket) do
    users = Users.list_users()
    first_user = Users.get_first_user()

    current_user =
      case socket.assigns do
        %{current_scope: %{user: user}} -> user
        %{current_user: user} -> user
        _ -> nil
      end

    {:ok,
     socket
     |> assign(:users, users)
     |> assign(:first_user, first_user)
     |> assign(:current_user, current_user)
     |> assign(:create_user_form, to_form(%{"email" => ""}))
     |> assign(:login_link, nil)
     |> assign(:user_login_link, nil)}
  end

  @impl true
  def handle_event("delete_user", %{"user_id" => user_id}, socket) do
    try do
      user = Users.get_user!(user_id)
      current_user = socket.assigns.current_user

      cond do
        # Handle case where current_user is nil
        is_nil(current_user) ->
          {:noreply,
           socket
           |> put_flash(:error, "Authentication required.")}

        # Prevent user from deleting themselves
        user.id == current_user.id ->
          {:noreply,
           socket
           |> put_flash(:error, "You cannot delete your own account.")}

        # Prevent deleting the first user
        Users.first_user?(user) ->
          {:noreply,
           socket
           |> put_flash(:error, "The first user cannot be deleted.")}

        # Delete the user
        true ->
          case Users.delete_user(user) do
            {:ok, _deleted_user} ->
              {:noreply,
               socket
               |> put_flash(:info, "User #{user.email} has been deleted.")
               |> assign(:users, Users.list_users())}

            {:error, _changeset} ->
              {:noreply,
               socket
               |> put_flash(:error, "Failed to delete user.")}
          end
      end
    rescue
      Ecto.NoResultsError ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found.")}
    end
  end

  @impl true
  def handle_event("create_user", %{"email" => email}, socket) do
    case Users.create_user_with_login_link(%{email: email}) do
      {:ok, {user, login_url}} ->
        {:noreply,
         socket
         |> put_flash(:info, "User #{user.email} created successfully. Share the login link below.")
         |> assign(:users, Users.list_users())
         |> assign(:login_link, login_url)
         |> assign(:create_user_form, to_form(%{"email" => ""}))}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to create user.")
         |> assign(:create_user_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("show_login_link", %{"user_id" => user_id}, socket) do
    try do
      user = Users.get_user!(user_id)
      login_url = Users.generate_login_link_for_user(user)

      {:noreply,
       socket
       |> put_flash(:info, "Login link generated for #{user.email}. Share the link below.")
       |> assign(:user_login_link, login_url)}
    rescue
      Ecto.NoResultsError ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found.")}
    end
  end

  @impl true
  def handle_event("toggle_admin", %{"user_id" => user_id}, socket) do
    try do
      user = Users.get_user!(user_id)
      current_user = socket.assigns.current_user

      cond do
        # Handle case where current_user is nil
        is_nil(current_user) ->
          {:noreply,
           socket
           |> put_flash(:error, "Authentication required.")}

        # Prevent admin from removing their own admin status
        user.id == current_user.id ->
          {:noreply,
           socket
           |> put_flash(:error, "You cannot remove your own admin privileges.")}

        # Prevent removing admin status from the first user
        Users.first_user?(user) ->
          {:noreply,
           socket
           |> put_flash(:error, "The first user must always remain an admin.")}

        # Toggle admin status
        true ->
          new_admin_status = !user.admin

          changeset = Shard.Users.User.admin_changeset(user, %{admin: new_admin_status})

          case Repo.update(changeset) do
            {:ok, _updated_user} ->
              action = if new_admin_status, do: "granted", else: "revoked"

              {:noreply,
               socket
               |> put_flash(:info, "Admin privileges #{action} for #{user.email}.")
               |> assign(:users, Users.list_users())}

            {:error, _changeset} ->
              {:noreply,
               socket
               |> put_flash(:error, "Failed to update user privileges.")}
          end
      end
    rescue
      Ecto.NoResultsError ->
        {:noreply,
         socket
         |> put_flash(:error, "User not found.")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        User Management
        <:subtitle>Manage user accounts and administrative privileges</:subtitle>
      </.header>

      <div class="mt-8">
        <.form for={@create_user_form} id="create-user-form" phx-submit="create_user" class="mb-6">
          <div class="flex gap-4 items-end">
            <.input field={@create_user_form[:email]} type="email" label="New User Email" placeholder="user@example.com" required />
            <.button type="submit" class="btn btn-primary">Create User</.button>
          </div>
        </.form>

        <%= if @login_link do %>
          <div class="alert alert-info mb-6">
            <strong>Login Link:</strong> <a href={@login_link} target="_blank" class="link">{@login_link}</a>
            <p class="text-sm mt-2">Copy and send this link to the user for their first login.</p>
          </div>
        <% end %>

        <%= if @user_login_link do %>
          <div class="alert alert-info mb-6">
            <strong>User Login Link:</strong> <a href={@user_login_link} target="_blank" class="link">{@user_login_link}</a>
            <p class="text-sm mt-2">Copy and send this link to the user.</p>
          </div>
        <% end %>
        <div class="overflow-x-auto">
          <table class="table table-zebra w-full">
            <thead>
              <tr>
                <th>Email</th>
                <th>Admin Status</th>
                <th>Confirmed</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              <tr :for={user <- @users} class="hover">
                <td class="font-medium">
                  {user.email}
                  <%= if Users.first_user?(user) do %>
                    <span class="badge badge-primary badge-sm ml-2">First User</span>
                  <% end %>
                  <%= if @current_user && user.id == @current_user.id do %>
                    <span class="badge badge-secondary badge-sm ml-2">You</span>
                  <% end %>
                </td>
                <td>
                  <%= if user.admin do %>
                    <span class="badge badge-success">Admin</span>
                  <% else %>
                    <span class="badge badge-ghost">User</span>
                  <% end %>
                </td>
                <td>
                  <%= if user.confirmed_at do %>
                    <span class="badge badge-success">Confirmed</span>
                  <% else %>
                    <span class="badge badge-warning">Unconfirmed</span>
                  <% end %>
                </td>
                <td>
                  <div class="flex gap-2">
                    <%= cond do %>
                      <% Users.first_user?(user) -> %>
                        <span class="text-gray-500 text-sm">Protected user</span>
                      <% @current_user && user.id == @current_user.id -> %>
                        <span class="text-gray-500 text-sm">Cannot modify yourself</span>
                      <% true -> %>
                        <button
                          class={[
                            "btn btn-sm",
                            if(user.admin, do: "btn-warning", else: "btn-success")
                          ]}
                          phx-click="toggle_admin"
                          phx-value-user_id={user.id}
                          data-confirm={
                            if user.admin do
                              "Are you sure you want to revoke admin privileges from #{user.email}?"
                            else
                              "Are you sure you want to grant admin privileges to #{user.email}?"
                            end
                          }
                        >
                          {if user.admin, do: "Revoke Admin", else: "Grant Admin"}
                        </button>

                        <button
                          class="btn btn-sm btn-info"
                          phx-click="show_login_link"
                          phx-value-user_id={user.id}
                        >
                          Show Login Link
                        </button>

                        <button
                          class="btn btn-sm btn-error"
                          phx-click="delete_user"
                          phx-value-user_id={user.id}
                          data-confirm="Are you sure you want to delete #{user.email}? This action cannot be undone and will remove all associated data."
                        >
                          Delete
                        </button>
                    <% end %>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
