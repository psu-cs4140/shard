defmodule ShardWeb.FriendsLive.Index do
  use ShardWeb, :live_view

  alias Shard.Social

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    # Subscribe to user's conversation updates
    Phoenix.PubSub.subscribe(Shard.PubSub, "user:#{user_id}:conversations")

    friends = Social.list_friends(user_id)
    friends_with_party_status = add_party_status_to_friends(friends)

    {:ok,
     socket
     |> assign(:active_tab, "friends")
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:show_search_dropdown, false)
     |> assign(:friends, friends_with_party_status)
     |> assign(:pending_requests, Social.list_pending_friend_requests(user_id))
     |> assign(:sent_requests, Social.list_sent_friend_requests(user_id))
     |> assign(:conversations, Social.list_user_conversations(user_id))
     |> assign(:active_conversation, nil)
     |> assign(:party, Social.get_user_party(user_id))
     |> assign(:pending_party_invitations, Social.list_pending_party_invitations(user_id))
     |> assign(:sent_party_invitations, Social.list_sent_party_invitations(user_id))
     |> assign(:new_message, "")
     |> assign(:show_new_conversation_form, false)
     |> assign(:selected_friends, [])
     |> assign(:show_conversation_settings, false)
     |> assign(:editing_conversation_name, false)
     |> assign(:new_conversation_name, "")
     |> assign(:show_add_participants, false)
     |> assign(:selected_new_participants, [])}
  end

  # Helper function to add party status to friends
  defp add_party_status_to_friends(friends) do
    Enum.map(friends, fn %{friend: friend} = friend_data ->
      party = Social.get_user_party(friend.id)
      Map.put(friend_data, :in_party, !is_nil(party))
    end)
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

  # Handle messages from components
  @impl true
  def handle_info({:update_search, query, results, show_dropdown}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:search_results, results)
     |> assign(:show_search_dropdown, show_dropdown)}
  end

  def handle_info({:update_search_dropdown, show_dropdown}, socket) do
    {:noreply, assign(socket, :show_search_dropdown, show_dropdown)}
  end

  def handle_info(:hide_dropdown, socket) do
    {:noreply, assign(socket, :show_search_dropdown, false)}
  end

  def handle_info({:friend_request_sent, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:search_query, "")
     |> assign(:search_results, [])
     |> assign(:show_search_dropdown, false)}
  end

  def handle_info({:friend_request_accepted, message}, socket) do
    user_id = socket.assigns.current_scope.user.id
    friends = Social.list_friends(user_id)
    friends_with_party_status = add_party_status_to_friends(friends)

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:friends, friends_with_party_status)
     |> assign(:pending_requests, Social.list_pending_friend_requests(user_id))
     |> assign(:sent_requests, Social.list_sent_friend_requests(user_id))}
  end

  def handle_info({:friend_request_declined, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:pending_requests, Social.list_pending_friend_requests(user_id))
     |> assign(:sent_requests, Social.list_sent_friend_requests(user_id))}
  end

  def handle_info({:friend_removed, message}, socket) do
    user_id = socket.assigns.current_scope.user.id
    friends = Social.list_friends(user_id)
    friends_with_party_status = add_party_status_to_friends(friends)

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:friends, friends_with_party_status)}
  end

  # Chat-related messages
  def handle_info({:show_new_conversation_form}, socket) do
    {:noreply, assign(socket, :show_new_conversation_form, true)}
  end

  def handle_info({:hide_new_conversation_form}, socket) do
    {:noreply,
     socket
     |> assign(:show_new_conversation_form, false)
     |> assign(:selected_friends, [])}
  end

  def handle_info({:toggle_friend_selection, friend_id}, socket) do
    selected_friends = socket.assigns.selected_friends

    new_selected =
      if friend_id in selected_friends do
        List.delete(selected_friends, friend_id)
      else
        [friend_id | selected_friends]
      end

    {:noreply, assign(socket, :selected_friends, new_selected)}
  end

  def handle_info({:conversation_created, conversation, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:show_new_conversation_form, false)
     |> assign(:selected_friends, [])
     |> assign(:conversations, Social.list_user_conversations(user_id))
     |> assign(:active_conversation, Social.get_conversation_with_messages(conversation.id))}
  end

  def handle_info({:existing_conversation_opened, existing_conversation, message}, socket) do
    conversation_with_messages = Social.get_conversation_with_messages(existing_conversation.id)
    Phoenix.PubSub.subscribe(Shard.PubSub, "conversation:#{existing_conversation.id}")

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:show_new_conversation_form, false)
     |> assign(:selected_friends, [])
     |> assign(:active_conversation, conversation_with_messages)}
  end

  def handle_info({:open_conversation, conversation_id}, socket) do
    conversation = Social.get_conversation_with_messages(conversation_id)
    Phoenix.PubSub.subscribe(Shard.PubSub, "conversation:#{conversation_id}")

    {:noreply, assign(socket, :active_conversation, conversation)}
  end

  def handle_info({:update_message, content}, socket) do
    {:noreply, assign(socket, :new_message, content)}
  end

  def handle_info({:message_sent}, socket) do
    case socket.assigns.active_conversation do
      nil ->
        {:noreply, socket}

      conversation ->
        updated_conversation = Social.get_conversation_with_messages(conversation.id)

        {:noreply,
         socket
         |> assign(:active_conversation, updated_conversation)
         |> assign(:new_message, "")}
    end
  end

  def handle_info({:show_conversation_settings}, socket) do
    {:noreply, assign(socket, :show_conversation_settings, true)}
  end

  def handle_info({:hide_conversation_settings}, socket) do
    {:noreply,
     socket
     |> assign(:show_conversation_settings, false)
     |> assign(:editing_conversation_name, false)
     |> assign(:new_conversation_name, "")
     |> assign(:show_add_participants, false)
     |> assign(:selected_new_participants, [])}
  end

  def handle_info({:start_edit_conversation_name, current_name}, socket) do
    {:noreply,
     socket
     |> assign(:editing_conversation_name, true)
     |> assign(:new_conversation_name, current_name)}
  end

  def handle_info({:cancel_edit_conversation_name}, socket) do
    {:noreply,
     socket
     |> assign(:editing_conversation_name, false)
     |> assign(:new_conversation_name, "")}
  end

  def handle_info({:conversation_name_updated, updated_conversation, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:editing_conversation_name, false)
     |> assign(:new_conversation_name, "")
     |> assign(
       :active_conversation,
       Social.get_conversation_with_messages(updated_conversation.id)
     )
     |> assign(:conversations, Social.list_user_conversations(user_id))}
  end

  def handle_info({:conversation_deleted, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:active_conversation, nil)
     |> assign(:show_conversation_settings, false)
     |> assign(:conversations, Social.list_user_conversations(user_id))}
  end

  def handle_info({:show_add_participants}, socket) do
    {:noreply, assign(socket, :show_add_participants, true)}
  end

  def handle_info({:hide_add_participants}, socket) do
    {:noreply,
     socket
     |> assign(:show_add_participants, false)
     |> assign(:selected_new_participants, [])}
  end

  def handle_info({:toggle_new_participant_selection, friend_id}, socket) do
    selected = socket.assigns.selected_new_participants

    new_selected =
      if friend_id in selected do
        List.delete(selected, friend_id)
      else
        [friend_id | selected]
      end

    {:noreply, assign(socket, :selected_new_participants, new_selected)}
  end

  def handle_info({:participants_added, conversation_id, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:show_add_participants, false)
     |> assign(:selected_new_participants, [])
     |> assign(:active_conversation, Social.get_conversation_with_messages(conversation_id))
     |> assign(:conversations, Social.list_user_conversations(user_id))}
  end

  def handle_info({:participant_removed, conversation_id, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:active_conversation, Social.get_conversation_with_messages(conversation_id))
     |> assign(:conversations, Social.list_user_conversations(user_id))}
  end

  # Party-related messages
  def handle_info({:party_created, party, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:party, party)}
  end

  def handle_info({:party_left, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:party, nil)}
  end

  def handle_info({:party_invitation_sent, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:party, Social.get_user_party(user_id))
     |> assign(:sent_party_invitations, Social.list_sent_party_invitations(user_id))}
  end

  def handle_info({:party_disbanded, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:party, nil)}
  end

  def handle_info({:party_member_kicked, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:party, Social.get_user_party(user_id))}
  end

  def handle_info({:party_invitation_accepted, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:party, Social.get_user_party(user_id))
     |> assign(:pending_party_invitations, Social.list_pending_party_invitations(user_id))}
  end

  def handle_info({:party_invitation_declined, message}, socket) do
    user_id = socket.assigns.current_scope.user.id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> assign(:pending_party_invitations, Social.list_pending_party_invitations(user_id))}
  end

  def handle_info({:error, message}, socket) do
    {:noreply, put_flash(socket, :error, message)}
  end

  # Existing PubSub handlers
  @impl true
  def handle_info({:new_message, conversation_id}, socket) do
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
      <div :if={@active_tab == "friends"}>
        <.live_component
          module={ShardWeb.FriendsLive.FriendsTab}
          id="friends-tab"
          current_user_id={@current_scope.user.id}
          search_query={@search_query}
          search_results={@search_results}
          show_search_dropdown={@show_search_dropdown}
          friends={@friends}
          pending_requests={@pending_requests}
          sent_requests={@sent_requests}
        />
      </div>
      
    <!-- Chat Tab -->
      <div :if={@active_tab == "chat"}>
        <.live_component
          module={ShardWeb.FriendsLive.ChatTab}
          id="chat-tab"
          current_user_id={@current_scope.user.id}
          friends={@friends}
          conversations={@conversations}
          active_conversation={@active_conversation}
          show_new_conversation_form={@show_new_conversation_form}
          selected_friends={@selected_friends}
          new_message={@new_message}
          show_conversation_settings={@show_conversation_settings}
          editing_conversation_name={@editing_conversation_name}
          new_conversation_name={@new_conversation_name}
          show_add_participants={@show_add_participants}
          selected_new_participants={@selected_new_participants}
        />
      </div>
      
    <!-- Party Tab -->
      <div :if={@active_tab == "party"}>
        <.live_component
          module={ShardWeb.FriendsLive.PartyTab}
          id="party-tab"
          current_user_id={@current_scope.user.id}
          friends={@friends}
          party={@party}
          pending_party_invitations={@pending_party_invitations}
          sent_party_invitations={@sent_party_invitations}
        />
      </div>
    </div>
    """
  end
end
