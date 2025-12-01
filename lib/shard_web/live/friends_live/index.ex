defmodule ShardWeb.FriendsLive.Index do
  use ShardWeb, :live_view

  alias Shard.Social

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    # Subscribe to user's conversation updates
    Phoenix.PubSub.subscribe(Shard.PubSub, "user:#{user_id}:conversations")

    {:ok,
     socket
     |> assign(:active_tab, "friends")
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:show_search_dropdown, false)
     |> assign(:friends, Social.list_friends(user_id))
     |> assign(:pending_requests, Social.list_pending_friend_requests(user_id))
     |> assign(:sent_requests, Social.list_sent_friend_requests(user_id))
     |> assign(:conversations, Social.list_user_conversations(user_id))
     |> assign(:active_conversation, nil)
     |> assign(:party, Social.get_user_party(user_id))
     |> assign(:new_message, "")
     |> assign(:show_new_conversation_form, false)
     |> assign(:selected_friends, [])
     |> assign(:show_conversation_settings, false)
     |> assign(:editing_conversation_name, false)
     |> assign(:new_conversation_name, "")
     |> assign(:show_add_participants, false)
     |> assign(:selected_new_participants, [])}
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

  def handle_event("search_users", %{"query" => query}, socket) do
    user_id = socket.assigns.current_scope.user.id
    results = Social.search_users(query, user_id)
    show_dropdown = byte_size(query) >= 1 && results != []
    
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, results)
     |> assign(:show_search_dropdown, show_dropdown)}
  end

  def handle_event("focus_search", _params, socket) do
    show_dropdown = socket.assigns.search_query != "" && socket.assigns.search_results != []
    {:noreply, assign(socket, :show_search_dropdown, show_dropdown)}
  end

  def handle_event("blur_search", _params, socket) do
    # Delay hiding dropdown to allow clicks on dropdown items
    Process.send_after(self(), :hide_dropdown, 200)
    {:noreply, socket}
  end

  def handle_event("hide_search_dropdown", _params, socket) do
    {:noreply, assign(socket, :show_search_dropdown, false)}
  end

  def handle_event("send_friend_request", %{"user_id" => friend_id}, socket) do
    user_id = socket.assigns.current_scope.user.id
    
    case Social.send_friend_request(user_id, String.to_integer(friend_id)) do
      {:ok, _friendship} ->
        {:noreply,
         socket
         |> put_flash(:info, "Friend request sent!")
         |> assign(:search_query, "")
         |> assign(:search_results, [])
         |> assign(:show_search_dropdown, false)}
      
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
         |> assign(:pending_requests, Social.list_pending_friend_requests(user_id))
         |> assign(:sent_requests, Social.list_sent_friend_requests(user_id))}
      
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
         |> assign(:pending_requests, Social.list_pending_friend_requests(user_id))
         |> assign(:sent_requests, Social.list_sent_friend_requests(user_id))}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not decline friend request")}
    end
  end

  def handle_event("open_conversation", %{"conversation_id" => conversation_id}, socket) do
    conversation_id = String.to_integer(conversation_id)
    conversation = Social.get_conversation_with_messages(conversation_id)
    
    # Subscribe to this specific conversation for real-time updates
    Phoenix.PubSub.subscribe(Shard.PubSub, "conversation:#{conversation_id}")
    
    {:noreply, assign(socket, :active_conversation, conversation)}
  end

  def handle_event("update_message", %{"message" => content}, socket) do
    {:noreply, assign(socket, :new_message, content)}
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

  def handle_event("remove_friend", %{"friend_id" => friend_id}, socket) do
    user_id = socket.assigns.current_scope.user.id
    
    case Social.remove_friend(user_id, String.to_integer(friend_id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Friend removed")
         |> assign(:friends, Social.list_friends(user_id))}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not remove friend")}
    end
  end

  def handle_event("show_new_conversation_form", _params, socket) do
    {:noreply, assign(socket, :show_new_conversation_form, true)}
  end

  def handle_event("hide_new_conversation_form", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_new_conversation_form, false)
     |> assign(:selected_friends, [])}
  end

  def handle_event("toggle_friend_selection", %{"friend_id" => friend_id}, socket) do
    friend_id = String.to_integer(friend_id)
    selected_friends = socket.assigns.selected_friends
    
    new_selected = 
      if friend_id in selected_friends do
        List.delete(selected_friends, friend_id)
      else
        [friend_id | selected_friends]
      end
    
    {:noreply, assign(socket, :selected_friends, new_selected)}
  end

  def handle_event("show_conversation_settings", _params, socket) do
    {:noreply, assign(socket, :show_conversation_settings, true)}
  end

  def handle_event("hide_conversation_settings", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_conversation_settings, false)
     |> assign(:editing_conversation_name, false)
     |> assign(:new_conversation_name, "")
     |> assign(:show_add_participants, false)
     |> assign(:selected_new_participants, [])}
  end

  def handle_event("start_edit_conversation_name", _params, socket) do
    current_name = socket.assigns.active_conversation.name || ""
    {:noreply, 
     socket
     |> assign(:editing_conversation_name, true)
     |> assign(:new_conversation_name, current_name)}
  end

  def handle_event("cancel_edit_conversation_name", _params, socket) do
    {:noreply, 
     socket
     |> assign(:editing_conversation_name, false)
     |> assign(:new_conversation_name, "")}
  end

  def handle_event("update_conversation_name", %{"name" => name}, socket) do
    conversation = socket.assigns.active_conversation
    
    case Social.update_conversation_name(conversation.id, String.trim(name)) do
      {:ok, updated_conversation} ->
        user_id = socket.assigns.current_scope.user.id
        
        {:noreply,
         socket
         |> put_flash(:info, "Conversation name updated!")
         |> assign(:editing_conversation_name, false)
         |> assign(:new_conversation_name, "")
         |> assign(:active_conversation, Social.get_conversation_with_messages(updated_conversation.id))
         |> assign(:conversations, Social.list_user_conversations(user_id))}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not update conversation name")}
    end
  end

  def handle_event("delete_conversation", _params, socket) do
    conversation = socket.assigns.active_conversation
    user_id = socket.assigns.current_scope.user.id
    
    case Social.delete_conversation(conversation.id, user_id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Conversation deleted")
         |> assign(:active_conversation, nil)
         |> assign(:show_conversation_settings, false)
         |> assign(:conversations, Social.list_user_conversations(user_id))}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete conversation")}
    end
  end

  def handle_event("show_add_participants", _params, socket) do
    {:noreply, assign(socket, :show_add_participants, true)}
  end

  def handle_event("hide_add_participants", _params, socket) do
    {:noreply, 
     socket
     |> assign(:show_add_participants, false)
     |> assign(:selected_new_participants, [])}
  end

  def handle_event("toggle_new_participant_selection", %{"friend_id" => friend_id}, socket) do
    friend_id = String.to_integer(friend_id)
    selected = socket.assigns.selected_new_participants
    
    new_selected = 
      if friend_id in selected do
        List.delete(selected, friend_id)
      else
        [friend_id | selected]
      end
    
    {:noreply, assign(socket, :selected_new_participants, new_selected)}
  end

  def handle_event("add_participants", _params, socket) do
    conversation = socket.assigns.active_conversation
    new_participant_ids = socket.assigns.selected_new_participants
    
    if new_participant_ids == [] do
      {:noreply, put_flash(socket, :error, "Please select at least one participant")}
    else
      case Social.add_participants_to_conversation(conversation.id, new_participant_ids) do
        {:ok, _} ->
          user_id = socket.assigns.current_scope.user.id
          
          {:noreply,
           socket
           |> put_flash(:info, "Participants added!")
           |> assign(:show_add_participants, false)
           |> assign(:selected_new_participants, [])
           |> assign(:active_conversation, Social.get_conversation_with_messages(conversation.id))
           |> assign(:conversations, Social.list_user_conversations(user_id))}
        
        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not add participants")}
      end
    end
  end

  def handle_event("remove_participant", %{"user_id" => user_id}, socket) do
    conversation = socket.assigns.active_conversation
    participant_id = String.to_integer(user_id)
    current_user_id = socket.assigns.current_scope.user.id
    
    case Social.remove_participant_from_conversation(conversation.id, participant_id) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Participant removed")
         |> assign(:active_conversation, Social.get_conversation_with_messages(conversation.id))
         |> assign(:conversations, Social.list_user_conversations(current_user_id))}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not remove participant")}
    end
  end

  def handle_event("create_conversation", %{"name" => name}, socket) do
    user_id = socket.assigns.current_scope.user.id
    selected_friends = socket.assigns.selected_friends
    
    if selected_friends == [] do
      {:noreply, put_flash(socket, :error, "Please select at least one friend")}
    else
      participant_ids = [user_id | selected_friends]
      
      # Check if conversation already exists with these participants
      case Social.find_existing_conversation(participant_ids) do
        nil ->
          # No existing conversation, create new one
          attrs = if String.trim(name) != "", do: %{name: String.trim(name)}, else: %{}
          
          case Social.create_conversation(participant_ids, attrs) do
            {:ok, conversation} ->
              {:noreply,
               socket
               |> put_flash(:info, "Conversation created!")
               |> assign(:show_new_conversation_form, false)
               |> assign(:selected_friends, [])
               |> assign(:conversations, Social.list_user_conversations(user_id))
               |> assign(:active_conversation, Social.get_conversation_with_messages(conversation.id))}
            
            {:error, _} ->
              {:noreply, put_flash(socket, :error, "Could not create conversation")}
          end
        
        existing_conversation ->
          # Conversation already exists, open it instead
          conversation_with_messages = Social.get_conversation_with_messages(existing_conversation.id)
          Phoenix.PubSub.subscribe(Shard.PubSub, "conversation:#{existing_conversation.id}")
          
          {:noreply,
           socket
           |> put_flash(:info, "Opened existing conversation")
           |> assign(:show_new_conversation_form, false)
           |> assign(:selected_friends, [])
           |> assign(:active_conversation, conversation_with_messages)}
      end
    end
  end

  @impl true
  def handle_info(:hide_dropdown, socket) do
    {:noreply, assign(socket, :show_search_dropdown, false)}
  end

  @impl true
  def handle_info({:new_message, conversation_id}, socket) do
    # Update the active conversation if it matches the one that received a new message
    case socket.assigns.active_conversation do
      %{id: ^conversation_id} ->
        updated_conversation = Social.get_conversation_with_messages(conversation_id)
        {:noreply, assign(socket, :active_conversation, updated_conversation)}
      
      _ ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:conversation_created, _conversation}, socket) do
    # Refresh conversations list when a new conversation is created
    user_id = socket.assigns.current_scope.user.id
    {:noreply, assign(socket, :conversations, Social.list_user_conversations(user_id))}
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
            <div class="relative">
              <form phx-change="search_users" phx-submit="search_users">
                <input
                  type="text"
                  name="query"
                  value={@search_query}
                  placeholder="Search by email..."
                  class="input input-bordered w-full"
                  phx-focus="focus_search"
                  phx-blur="blur_search"
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

        <!-- Sent Requests -->
        <div :if={@sent_requests != []} class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Sent Friend Requests</h2>
            <div class="space-y-2">
              <div :for={%{friendship: friendship, recipient: user} <- @sent_requests} class="flex items-center justify-between p-2 bg-base-200 rounded">
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
              <div :for={%{friend: friend} <- @friends} class="flex items-center justify-between p-2 bg-base-200 rounded">
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
                >
                  Remove
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Chat Tab -->
      <div :if={@active_tab == "chat"} class="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[600px]">
        <!-- Conversations List -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="flex items-center justify-between mb-4">
              <h2 class="card-title">Conversations</h2>
              <button 
                class="btn btn-primary btn-sm"
                phx-click="show_new_conversation_form"
              >
                New Chat
              </button>
            </div>
            
            <!-- New Conversation Form -->
            <div :if={@show_new_conversation_form} class="mb-4 p-4 bg-base-200 rounded-lg">
              <form phx-submit="create_conversation">
                <div class="space-y-3">
                  <div>
                    <label class="label">
                      <span class="label-text">Conversation Name (optional)</span>
                    </label>
                    <input
                      type="text"
                      name="name"
                      placeholder="Enter conversation name..."
                      class="input input-bordered input-sm w-full"
                    />
                  </div>
                  
                  <div>
                    <label class="label">
                      <span class="label-text">Select Friends</span>
                    </label>
                    <div :if={@friends == []} class="text-sm text-base-content/60">
                      No friends available. Add friends first!
                    </div>
                    <div :if={@friends != []} class="space-y-1 max-h-32 overflow-y-auto">
                      <label 
                        :for={%{friend: friend} <- @friends}
                        class="flex items-center space-x-2 p-1 hover:bg-base-300 rounded cursor-pointer"
                      >
                        <input
                          type="checkbox"
                          class="checkbox checkbox-sm"
                          phx-click="toggle_friend_selection"
                          phx-value-friend_id={friend.id}
                          checked={friend.id in @selected_friends}
                        />
                        <span class="text-sm">{friend.email}</span>
                      </label>
                    </div>
                  </div>
                  
                  <div class="flex space-x-2">
                    <button type="submit" class="btn btn-primary btn-sm">
                      Create
                    </button>
                    <button 
                      type="button" 
                      class="btn btn-ghost btn-sm"
                      phx-click="hide_new_conversation_form"
                    >
                      Cancel
                    </button>
                  </div>
                </div>
              </form>
            </div>
            
            <div :if={@conversations == []} class="text-center text-base-content/60 py-8">
              No conversations yet
            </div>
            <div :if={@conversations != []} class="space-y-2">
              <div
                :for={conversation <- @conversations}
                class={[
                  "p-2 rounded cursor-pointer hover:bg-base-300",
                  if(@active_conversation && @active_conversation.id == conversation.id, do: "bg-primary text-primary-content", else: "bg-base-200")
                ]}
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
        <div class="lg:col-span-2 card bg-base-100 shadow-xl h-full">
          <div class="card-body h-full flex flex-col">
            <div :if={@active_conversation == nil} class="flex-1 flex items-center justify-center text-center text-base-content/60">
              Select a conversation to start chatting
            </div>
            <div :if={@active_conversation != nil} class="flex flex-col h-full">
              <div class="flex items-center justify-between mb-4 flex-shrink-0">
                <h2 class="card-title">
                  {@active_conversation.name || "Direct Message"}
                </h2>
                <button 
                  class="btn btn-ghost btn-sm"
                  phx-click="show_conversation_settings"
                >
                  ⚙️
                </button>
              </div>

              <!-- Conversation Settings Modal -->
              <div :if={@show_conversation_settings} class="mb-4 p-4 bg-base-200 rounded-lg">
                <div class="flex items-center justify-between mb-3">
                  <h3 class="font-semibold">Conversation Settings</h3>
                  <button 
                    class="btn btn-ghost btn-xs"
                    phx-click="hide_conversation_settings"
                  >
                    ✕
                  </button>
                </div>

                <!-- Edit Name Section -->
                <div class="mb-4">
                  <div :if={!@editing_conversation_name} class="flex items-center justify-between">
                    <span class="text-sm">Name: {@active_conversation.name || "Direct Message"}</span>
                    <button 
                      class="btn btn-primary btn-xs"
                      phx-click="start_edit_conversation_name"
                    >
                      Edit
                    </button>
                  </div>
                  
                  <div :if={@editing_conversation_name}>
                    <form phx-submit="update_conversation_name">
                      <div class="flex space-x-2">
                        <input
                          type="text"
                          name="name"
                          value={@new_conversation_name}
                          placeholder="Enter conversation name..."
                          class="input input-bordered input-xs flex-1"
                          required
                        />
                        <button type="submit" class="btn btn-primary btn-xs">Save</button>
                        <button 
                          type="button" 
                          class="btn btn-ghost btn-xs"
                          phx-click="cancel_edit_conversation_name"
                        >
                          Cancel
                        </button>
                      </div>
                    </form>
                  </div>
                </div>

                <!-- Participants Section -->
                <div class="mb-4">
                  <div class="flex items-center justify-between mb-2">
                    <span class="text-sm font-medium">Participants ({length(@active_conversation.participants)})</span>
                    <button 
                      class="btn btn-primary btn-xs"
                      phx-click="show_add_participants"
                    >
                      Add
                    </button>
                  </div>
                  
                  <div class="space-y-1 max-h-24 overflow-y-auto">
                    <div 
                      :for={participant <- @active_conversation.participants}
                      class="flex items-center justify-between text-xs p-1 bg-base-100 rounded"
                    >
                      <span>{participant.email}</span>
                      <button 
                        :if={participant.id != @current_scope.user.id && length(@active_conversation.participants) > 2}
                        class="btn btn-error btn-xs"
                        phx-click="remove_participant"
                        phx-value-user_id={participant.id}
                      >
                        Remove
                      </button>
                    </div>
                  </div>

                  <!-- Add Participants Form -->
                  <div :if={@show_add_participants} class="mt-3 p-3 bg-base-100 rounded">
                    <div class="flex items-center justify-between mb-2">
                      <span class="text-xs font-medium">Add Friends</span>
                      <button 
                        class="btn btn-ghost btn-xs"
                        phx-click="hide_add_participants"
                      >
                        ✕
                      </button>
                    </div>
                    
                    <div :if={@friends == []} class="text-xs text-base-content/60">
                      No friends available to add.
                    </div>
                    
                    <div :if={@friends != []} class="space-y-1 max-h-20 overflow-y-auto mb-2">
                      <label 
                        :for={%{friend: friend} <- @friends}
                        :if={friend.id not in Enum.map(@active_conversation.participants, & &1.id)}
                        class="flex items-center space-x-2 text-xs hover:bg-base-200 rounded cursor-pointer p-1"
                      >
                        <input
                          type="checkbox"
                          class="checkbox checkbox-xs"
                          phx-click="toggle_new_participant_selection"
                          phx-value-friend_id={friend.id}
                          checked={friend.id in @selected_new_participants}
                        />
                        <span>{friend.email}</span>
                      </label>
                    </div>
                    
                    <button 
                      class="btn btn-primary btn-xs w-full"
                      phx-click="add_participants"
                    >
                      Add Selected
                    </button>
                  </div>
                </div>

                <!-- Delete Conversation -->
                <div class="border-t pt-3">
                  <button 
                    class="btn btn-error btn-sm w-full"
                    phx-click="delete_conversation"
                    onclick="return confirm('Are you sure you want to delete this conversation? This action cannot be undone.')"
                  >
                    Delete Conversation
                  </button>
                </div>
              </div>
              
              <!-- Messages Container -->
              <div 
                id="messages-container"
                class="h-96 overflow-y-auto space-y-2 mb-4 p-3 border border-base-300 rounded-lg bg-base-50"
                phx-hook="AutoScroll"
              >
                <div :for={message <- @active_conversation.messages} class="p-3 bg-base-100 rounded-lg shadow-sm">
                  <div class="flex items-center justify-between text-xs text-base-content/60 mb-1">
                    <span>{message.user.email}</span>
                    <span>{Calendar.strftime(message.inserted_at, "%m/%d %I:%M %p")}</span>
                  </div>
                  <div class="text-sm">{message.content}</div>
                </div>
              </div>
              
              <!-- Message Input -->
              <form phx-submit="send_message" phx-change="update_message" class="flex space-x-2 flex-shrink-0">
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
