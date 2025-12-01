defmodule ShardWeb.FriendsLive.Index do
  use ShardWeb, :live_view

  alias Shard.Social

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:ok,
     socket
     |> assign(:active_tab, "friends")
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:friends, Social.list_friends(user_id))
     |> assign(:pending_requests, Social.list_pending_friend_requests(user_id))
     |> assign(:conversations, Social.list_user_conversations(user_id))
     |> assign(:active_conversation, nil)
     |> assign(:party, Social.get_user_party(user_id))
     |> assign(:new_message, "")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = Map.get(params, "tab", "friends")
    {:noreply, assign(socket, :active_tab, tab)}
  end

  @impl true
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/friends?tab=#{tab}")}
  end

  def handle_event("search_users", %{"query" => query}, socket) when byte_size(query) >= 2 do
    user_id = socket.assigns.current_scope.user.id
    results = Social.search_users(query, user_id)
    
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, results)}
  end

  def handle_event("search_users", %{"query" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, [])}
  end

  def handle_event("send_friend_request", %{"user_id" => friend_id}, socket) do
    user_id = socket.assigns.current_scope.user.id
    
    case Social.send_friend_request(user_id, String.to_integer(friend_id)) do
      {:ok, _friendship} ->
        {:noreply,
         socket
         |> put_flash(:info, "Friend request sent!")
         |> assign(:search_results, [])}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not send friend request")}
    end
  end

  def handle_event("accept_friend_request", %{"friendship_id" => friendship_id}, socket) do
    case Social.accept_friend_request(String.to_integer(friendship_id)) do
      {:ok, _} ->
        user_id = socket.assigns.current_scope.user.id
        
        {:noreply,
         socket
         |> put_flash(:info, "Friend request accepted!")
         |> assign(:friends, Social.list_friends(user_id))
         |> assign(:pending_requests, Social.list_pending_friend_requests(user_id))}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not accept friend request")}
    end
  end

  def handle_event("decline_friend_request", %{"friendship_id" => friendship_id}, socket) do
    case Social.decline_friend_request(String.to_integer(friendship_id)) do
      {:ok, _} ->
        user_id = socket.assigns.current_scope.user.id
        
        {:noreply,
         socket
         |> put_flash(:info, "Friend request declined")
         |> assign(:pending_requests, Social.list_pending_friend_requests(user_id))}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not decline friend request")}
    end
  end

  def handle_event("open_conversation", %{"conversation_id" => conversation_id}, socket) do
    conversation = Social.get_conversation_with_messages(String.to_integer(conversation_id))
    
    {:noreply, assign(socket, :active_conversation, conversation)}
  end

  def handle_event("send_message", %{"message" => content}, socket) do
    case socket.assigns.active_conversation do
      nil ->
        {:noreply, socket}
      
      conversation ->
        user_id = socket.assigns.current_scope.user.id
        
        case Social.send_message(conversation.id, user_id, content) do
          {:ok, _message} ->
            updated_conversation = Social.get_conversation_with_messages(conversation.id)
            
            {:noreply,
             socket
             |> assign(:active_conversation, updated_conversation)
             |> assign(:new_message, "")}
          
          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Could not send message")}
        end
    end
  end

  def handle_event("create_party", _params, socket) do
    user_id = socket.assigns.current_scope.user.id
    
    case Social.create_party(user_id) do
      {:ok, party} ->
        {:noreply,
         socket
         |> put_flash(:info, "Party created!")
         |> assign(:party, party)}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not create party")}
    end
  end

  def handle_event("leave_party", _params, socket) do
    user_id = socket.assigns.current_scope.user.id
    
    case Social.leave_party(user_id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Left party")
         |> assign(:party, nil)}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not leave party")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-6">
      <h1 class="text-3xl font-bold mb-6">Social</h1>
      
      <!-- Tab Navigation -->
      <div class="tabs tabs-boxed mb-6">
        <button
          class={["tab", @active_tab == "friends" && "tab-active"]}
          phx-click="switch_tab"
          phx-value-tab="friends"
        >
          Friends
        </button>
        <button
          class={["tab", @active_tab == "chat" && "tab-active"]}
          phx-click="switch_tab"
          phx-value-tab="chat"
        >
          Chat
        </button>
        <button
          class={["tab", @active_tab == "party" && "tab-active"]}
          phx-click="switch_tab"
          phx-value-tab="party"
        >
          Party
        </button>
      </div>

      <!-- Friends Tab -->
      <div :if={@active_tab == "friends"} class="space-y-6">
        <!-- Search Bar -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Find Friends</h2>
            <form phx-change="search_users" phx-submit="search_users">
              <input
                type="text"
                name="query"
                value={@search_query}
                placeholder="Search by email..."
                class="input input-bordered w-full"
              />
            </form>
            
            <div :if={@search_results != []} class="mt-4 space-y-2">
              <div :for={user <- @search_results} class="flex items-center justify-between p-2 bg-base-200 rounded">
                <span>{user.email}</span>
                <button
                  class="btn btn-primary btn-sm"
                  phx-click="send_friend_request"
                  phx-value-user_id={user.id}
                >
                  Add Friend
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Pending Requests -->
        <div :if={@pending_requests != []} class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Pending Friend Requests</h2>
            <div class="space-y-2">
              <div :for={%{friendship: friendship, requester: user} <- @pending_requests} class="flex items-center justify-between p-2 bg-base-200 rounded">
                <span>{user.email}</span>
                <div class="space-x-2">
                  <button
                    class="btn btn-success btn-sm"
                    phx-click="accept_friend_request"
                    phx-value-friendship_id={friendship.id}
                  >
                    Accept
                  </button>
                  <button
                    class="btn btn-error btn-sm"
                    phx-click="decline_friend_request"
                    phx-value-friendship_id={friendship.id}
                  >
                    Decline
                  </button>
                </div>
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
              <div :for={%{friend: friend} <- @friends} class="flex items-center justify-between p-2 bg-base-200 rounded">
                <div class="flex items-center space-x-3">
                  <div class="avatar placeholder">
                    <div class="bg-neutral text-neutral-content rounded-full w-8">
                      <span class="text-xs">{String.first(friend.email)}</span>
                    </div>
                  </div>
                  <span>{friend.email}</span>
                  <span class="badge badge-success">Online</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Chat Tab -->
      <div :if={@active_tab == "chat"} class="grid grid-cols-1 lg:grid-cols-3 gap-6 h-96">
        <!-- Conversations List -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Conversations</h2>
            <div :if={@conversations == []} class="text-center text-base-content/60 py-8">
              No conversations yet
            </div>
            <div :if={@conversations != []} class="space-y-2">
              <div
                :for={conversation <- @conversations}
                class="p-2 bg-base-200 rounded cursor-pointer hover:bg-base-300"
                phx-click="open_conversation"
                phx-value-conversation_id={conversation.id}
              >
                <div class="font-medium">
                  {conversation.name || "Direct Message"}
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Active Conversation -->
        <div class="lg:col-span-2 card bg-base-100 shadow-xl">
          <div class="card-body">
            <div :if={@active_conversation == nil} class="text-center text-base-content/60 py-8">
              Select a conversation to start chatting
            </div>
            <div :if={@active_conversation != nil} class="flex flex-col h-full">
              <h2 class="card-title mb-4">
                {@active_conversation.name || "Direct Message"}
              </h2>
              
              <!-- Messages -->
              <div class="flex-1 overflow-y-auto space-y-2 mb-4">
                <div :for={message <- @active_conversation.messages} class="p-2 bg-base-200 rounded">
                  <div class="text-sm text-base-content/60">{message.user.email}</div>
                  <div>{message.content}</div>
                </div>
              </div>
              
              <!-- Message Input -->
              <form phx-submit="send_message" class="flex space-x-2">
                <input
                  type="text"
                  name="message"
                  value={@new_message}
                  placeholder="Type a message..."
                  class="input input-bordered flex-1"
                  required
                />
                <button type="submit" class="btn btn-primary">Send</button>
              </form>
            </div>
          </div>
        </div>
      </div>

      <!-- Party Tab -->
      <div :if={@active_tab == "party"} class="space-y-6">
        <div :if={@party == nil} class="card bg-base-100 shadow-xl">
          <div class="card-body text-center">
            <h2 class="card-title">No Party</h2>
            <p>You're not currently in a party.</p>
            <div class="card-actions justify-center">
              <button class="btn btn-primary" phx-click="create_party">
                Create Party
              </button>
            </div>
          </div>
        </div>

        <div :if={@party != nil} class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="flex items-center justify-between">
              <h2 class="card-title">Your Party</h2>
              <button class="btn btn-error btn-sm" phx-click="leave_party">
                Leave Party
              </button>
            </div>
            
            <div class="space-y-2">
              <div :for={member <- @party.party_members} class="flex items-center space-x-3 p-2 bg-base-200 rounded">
                <div class="avatar placeholder">
                  <div class="bg-neutral text-neutral-content rounded-full w-8">
                    <span class="text-xs">{String.first(member.user.email)}</span>
                  </div>
                </div>
                <span>{member.user.email}</span>
                <span :if={member.user.id == @party.leader_id} class="badge badge-warning">Leader</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
