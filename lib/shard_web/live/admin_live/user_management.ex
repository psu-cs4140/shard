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
     |> assign(:current_user, current_user)}
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
    <.header>
      User Management
      <:subtitle>Manage user accounts and administrative privileges</:subtitle>
    </.header>

    <div class="mt-8">
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
    """
  end
end
