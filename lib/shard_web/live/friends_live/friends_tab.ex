defmodule ShardWeb.FriendsLive.FriendsTab do
  use ShardWeb, :live_component

  alias Shard.Social

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("search_users", %{"query" => query}, socket) do
    user_id = socket.assigns.current_user_id
    results = Social.search_users(query, user_id)
    show_dropdown = byte_size(query) >= 1 && results != []

    send(self(), {:update_search, query, results, show_dropdown})
    {:noreply, socket}
  end

  def handle_event("focus_search", _params, socket) do
    show_dropdown = socket.assigns.search_query != "" && socket.assigns.search_results != []
    send(self(), {:update_search_dropdown, show_dropdown})
    {:noreply, socket}
  end

  def handle_event("blur_search", _params, socket) do
    Process.send_after(self(), :hide_dropdown, 200)
    {:noreply, socket}
  end

  def handle_event("send_friend_request", %{"user_id" => friend_id}, socket) do
    user_id = socket.assigns.current_user_id

    case Social.send_friend_request(user_id, String.to_integer(friend_id)) do
      {:ok, _friendship} ->
        send(self(), {:friend_request_sent, "Friend request sent!"})
        {:noreply, socket}

      {:error, _changeset} ->
        send(self(), {:error, "Could not send friend request"})
        {:noreply, socket}
    end
  end

  def handle_event("accept_friend_request", %{"friendship_id" => friendship_id}, socket) do
    case Social.accept_friend_request(String.to_integer(friendship_id)) do
      {:ok, _} ->
        send(self(), {:friend_request_accepted, "Friend request accepted!"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not accept friend request"})
        {:noreply, socket}
    end
  end

  def handle_event("decline_friend_request", %{"friendship_id" => friendship_id}, socket) do
    case Social.decline_friend_request(String.to_integer(friendship_id)) do
      {:ok, _} ->
        send(self(), {:friend_request_declined, "Friend request declined"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not decline friend request"})
        {:noreply, socket}
    end
  end

  def handle_event("remove_friend", %{"friend_id" => friend_id}, socket) do
    user_id = socket.assigns.current_user_id

    case Social.remove_friend(user_id, String.to_integer(friend_id)) do
      {:ok, _} ->
        send(self(), {:friend_removed, "Friend removed"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not remove friend"})
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Search Bar -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">Find Friends</h2>
          <div class="relative">
            <form phx-change="search_users" phx-submit="search_users" phx-target={@myself}>
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Search by email..."
                class="input input-bordered w-full"
                phx-focus="focus_search"
                phx-blur="blur_search"
                phx-target={@myself}
                autocomplete="off"
              />
            </form>
            
            <!-- Search Dropdown -->
            <div
              :if={@show_search_dropdown && @search_results != []}
              class="absolute top-full left-0 right-0 z-50 mt-1 bg-base-100 border border-base-300 rounded-lg shadow-lg max-h-60 overflow-y-auto"
            >
              <div
                :for={user <- @search_results}
                class="flex items-center justify-between p-3 hover:bg-base-200 border-b border-base-300 last:border-b-0"
              >
                <div class="flex items-center space-x-3">
                  <div class="avatar placeholder">
                    <div class="bg-neutral text-neutral-content rounded-full w-8">
                      <span class="text-xs">{String.first(user.email)}</span>
                    </div>
                  </div>
                  <span class="text-sm">{user.email}</span>
                </div>
                <button
                  class="btn btn-primary btn-xs"
                  phx-click="send_friend_request"
                  phx-value-user_id={user.id}
                  phx-target={@myself}
                >
                  Add
                </button>
              </div>
            </div>
            
            <!-- No results message -->
            <div
              :if={@show_search_dropdown && @search_results == [] && @search_query != ""}
              class="absolute top-full left-0 right-0 z-50 mt-1 bg-base-100 border border-base-300 rounded-lg shadow-lg p-3 text-center text-base-content/60"
            >
              No users found
            </div>
          </div>
        </div>
      </div>
      
      <!-- Pending Requests -->
      <div :if={@pending_requests != []} class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">Incoming Friend Requests</h2>
          <div class="space-y-2">
            <div
              :for={%{friendship: friendship, requester: user} <- @pending_requests}
              class="flex items-center justify-between p-2 bg-base-200 rounded"
            >
              <span>{user.email}</span>
              <div class="space-x-2">
                <button
                  class="btn btn-success btn-sm"
                  phx-click="accept_friend_request"
                  phx-value-friendship_id={friendship.id}
                  phx-target={@myself}
                >
                  Accept
                </button>
                <button
                  class="btn btn-error btn-sm"
                  phx-click="decline_friend_request"
                  phx-value-friendship_id={friendship.id}
                  phx-target={@myself}
                >
                  Decline
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Sent Requests -->
      <div :if={@sent_requests != []} class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">Sent Friend Requests</h2>
          <div class="space-y-2">
            <div
              :for={%{friendship: friendship, recipient: user} <- @sent_requests}
              class="flex items-center justify-between p-2 bg-base-200 rounded"
            >
              <span>{user.email}</span>
              <span class="badge badge-warning">Pending</span>
            </div>
          </div>
        </div>
      </div>
      
      <!-- Friends List -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">Friends</h2>
          <div :if={@friends == []} class="text-center text-base-content/60 py-8">
            No friends yet. Search for users above to add friends!
          </div>
          <div :if={@friends != []} class="space-y-2">
            <div
              :for={%{friend: friend} <- @friends}
              class="flex items-center justify-between p-2 bg-base-200 rounded"
            >
              <div class="flex items-center space-x-3">
                <div class="avatar placeholder">
                  <div class="bg-neutral text-neutral-content rounded-full w-8">
                    <span class="text-xs">{String.first(friend.email)}</span>
                  </div>
                </div>
                <span>{friend.email}</span>
              </div>
              <button
                class="btn btn-error btn-sm"
                phx-click="remove_friend"
                phx-value-friend_id={friend.id}
                phx-target={@myself}
              >
                Remove
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
