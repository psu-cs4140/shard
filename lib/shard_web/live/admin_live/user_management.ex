defmodule ShardWeb.AdminLive.UserManagement do
  use ShardWeb, :live_view

  alias Shard.Users
  alias Shard.Users.User

  @impl true
  def mount(_params, _session, socket) do
    users = Users.list_users()
    first_user = Users.get_first_user()
    
    {:ok, 
     socket
     |> assign(:users, users)
     |> assign(:first_user, first_user)
     |> assign(:current_user, socket.assigns.current_scope.user)}
  end

  @impl true
  def handle_event("toggle_admin", %{"user_id" => user_id}, socket) do
    user = Users.get_user!(user_id)
    current_user = socket.assigns.current_user
    
    cond do
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
        
        case Users.update_user_admin_status(user, new_admin_status) do
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
                <%= user.email %>
                <%= if Users.first_user?(user) do %>
                  <span class="badge badge-primary badge-sm ml-2">First User</span>
                <% end %>
                <%= if user.id == @current_user.id do %>
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
                <%= cond do %>
                  <% user.id == @current_user.id -> %>
                    <span class="text-gray-500 text-sm">Cannot modify yourself</span>
                  <% Users.first_user?(user) -> %>
                    <span class="text-gray-500 text-sm">Protected user</span>
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
                      <%= if user.admin, do: "Revoke Admin", else: "Grant Admin" %>
                    </button>
                <% end %>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
