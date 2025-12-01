defmodule ShardWeb.FriendsLive.ChatTab do
  use ShardWeb, :live_component

  alias Shard.Social

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("show_new_conversation_form", _params, socket) do
    send(self(), {:show_new_conversation_form})
    {:noreply, socket}
  end

  def handle_event("hide_new_conversation_form", _params, socket) do
    send(self(), {:hide_new_conversation_form})
    {:noreply, socket}
  end

  def handle_event("toggle_friend_selection", %{"friend_id" => friend_id}, socket) do
    friend_id = String.to_integer(friend_id)
    send(self(), {:toggle_friend_selection, friend_id})
    {:noreply, socket}
  end

  def handle_event("create_conversation", %{"name" => name}, socket) do
    user_id = socket.assigns.current_user_id
    selected_friends = socket.assigns.selected_friends

    case validate_selected_friends(selected_friends) do
      :ok -> handle_conversation_creation(user_id, selected_friends, name, socket)
      :error -> send_error_and_reply(socket, "Please select at least one friend")
    end
  end

  defp validate_selected_friends([]), do: :error
  defp validate_selected_friends(_), do: :ok

  defp handle_conversation_creation(user_id, selected_friends, name, socket) do
    participant_ids = [user_id | selected_friends]

    case Social.find_existing_conversation(participant_ids) do
      nil -> create_new_conversation(participant_ids, name, socket)
      existing -> open_existing_conversation(existing, socket)
    end
  end

  defp create_new_conversation(participant_ids, name, socket) do
    attrs = build_conversation_attrs(name)

    case Social.create_conversation(participant_ids, attrs) do
      {:ok, conversation} ->
        send(self(), {:conversation_created, conversation, "Conversation created!"})
        {:noreply, socket}

      {:error, _} ->
        send_error_and_reply(socket, "Could not create conversation")
    end
  end

  defp build_conversation_attrs(name) do
    if String.trim(name) != "", do: %{name: String.trim(name)}, else: %{}
  end

  defp open_existing_conversation(existing_conversation, socket) do
    send(
      self(),
      {:existing_conversation_opened, existing_conversation, "Opened existing conversation"}
    )

    {:noreply, socket}
  end

  defp send_error_and_reply(socket, message) do
    send(self(), {:error, message})
    {:noreply, socket}
  end

  def handle_event("open_conversation", %{"conversation_id" => conversation_id}, socket) do
    conversation_id = String.to_integer(conversation_id)
    send(self(), {:open_conversation, conversation_id})
    {:noreply, socket}
  end

  def handle_event("update_message", %{"message" => content}, socket) do
    send(self(), {:update_message, content})
    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => content}, socket) do
    case socket.assigns.active_conversation do
      nil ->
        {:noreply, socket}

      conversation ->
        user_id = socket.assigns.current_user_id

        case Social.send_message(conversation.id, user_id, content) do
          {:ok, _message} ->
            send(self(), {:message_sent})
            {:noreply, socket}

          {:error, _} ->
            send(self(), {:error, "Could not send message"})
            {:noreply, socket}
        end
    end
  end

  def handle_event("show_conversation_settings", _params, socket) do
    send(self(), {:show_conversation_settings})
    {:noreply, socket}
  end

  def handle_event("hide_conversation_settings", _params, socket) do
    send(self(), {:hide_conversation_settings})
    {:noreply, socket}
  end

  def handle_event("start_edit_conversation_name", _params, socket) do
    current_name = socket.assigns.active_conversation.name || ""
    send(self(), {:start_edit_conversation_name, current_name})
    {:noreply, socket}
  end

  def handle_event("cancel_edit_conversation_name", _params, socket) do
    send(self(), {:cancel_edit_conversation_name})
    {:noreply, socket}
  end

  def handle_event("update_conversation_name", %{"name" => name}, socket) do
    conversation = socket.assigns.active_conversation

    case Social.update_conversation_name(conversation.id, String.trim(name)) do
      {:ok, updated_conversation} ->
        send(
          self(),
          {:conversation_name_updated, updated_conversation, "Conversation name updated!"}
        )

        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not update conversation name"})
        {:noreply, socket}
    end
  end

  def handle_event("delete_conversation", _params, socket) do
    conversation = socket.assigns.active_conversation
    user_id = socket.assigns.current_user_id

    case Social.delete_conversation(conversation.id, user_id) do
      {:ok, _} ->
        send(self(), {:conversation_deleted, "Conversation deleted"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not delete conversation"})
        {:noreply, socket}
    end
  end

  def handle_event("show_add_participants", _params, socket) do
    send(self(), {:show_add_participants})
    {:noreply, socket}
  end

  def handle_event("hide_add_participants", _params, socket) do
    send(self(), {:hide_add_participants})
    {:noreply, socket}
  end

  def handle_event("toggle_new_participant_selection", %{"friend_id" => friend_id}, socket) do
    friend_id = String.to_integer(friend_id)
    send(self(), {:toggle_new_participant_selection, friend_id})
    {:noreply, socket}
  end

  def handle_event("add_participants", _params, socket) do
    conversation = socket.assigns.active_conversation
    new_participant_ids = socket.assigns.selected_new_participants

    if new_participant_ids == [] do
      send(self(), {:error, "Please select at least one participant"})
      {:noreply, socket}
    else
      case Social.add_participants_to_conversation(conversation.id, new_participant_ids) do
        {:ok, _} ->
          send(self(), {:participants_added, conversation.id, "Participants added!"})
          {:noreply, socket}

        {:error, _} ->
          send(self(), {:error, "Could not add participants"})
          {:noreply, socket}
      end
    end
  end

  def handle_event("remove_participant", %{"user_id" => user_id}, socket) do
    conversation = socket.assigns.active_conversation
    participant_id = String.to_integer(user_id)

    case Social.remove_participant_from_conversation(conversation.id, participant_id) do
      {:ok, _} ->
        send(self(), {:participant_removed, conversation.id, "Participant removed"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not remove participant"})
        {:noreply, socket}
    end
  end

  def handle_event("open_conversation", %{"conversation_id" => conversation_id}, socket) do
    conversation_id = String.to_integer(conversation_id)
    send(self(), {:open_conversation, conversation_id})
    {:noreply, socket}
  end

  def handle_event("update_message", %{"message" => content}, socket) do
    send(self(), {:update_message, content})
    {:noreply, socket}
  end

  def handle_event("send_message", %{"message" => content}, socket) do
    case socket.assigns.active_conversation do
      nil ->
        {:noreply, socket}

      conversation ->
        user_id = socket.assigns.current_user_id

        case Social.send_message(conversation.id, user_id, content) do
          {:ok, _message} ->
            send(self(), {:message_sent})
            {:noreply, socket}

          {:error, _} ->
            send(self(), {:error, "Could not send message"})
            {:noreply, socket}
        end
    end
  end

  def handle_event("show_conversation_settings", _params, socket) do
    send(self(), {:show_conversation_settings})
    {:noreply, socket}
  end

  def handle_event("hide_conversation_settings", _params, socket) do
    send(self(), {:hide_conversation_settings})
    {:noreply, socket}
  end

  def handle_event("start_edit_conversation_name", _params, socket) do
    current_name = socket.assigns.active_conversation.name || ""
    send(self(), {:start_edit_conversation_name, current_name})
    {:noreply, socket}
  end

  def handle_event("cancel_edit_conversation_name", _params, socket) do
    send(self(), {:cancel_edit_conversation_name})
    {:noreply, socket}
  end

  def handle_event("update_conversation_name", %{"name" => name}, socket) do
    conversation = socket.assigns.active_conversation

    case Social.update_conversation_name(conversation.id, String.trim(name)) do
      {:ok, updated_conversation} ->
        send(
          self(),
          {:conversation_name_updated, updated_conversation, "Conversation name updated!"}
        )

        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not update conversation name"})
        {:noreply, socket}
    end
  end

  def handle_event("delete_conversation", _params, socket) do
    conversation = socket.assigns.active_conversation
    user_id = socket.assigns.current_user_id

    case Social.delete_conversation(conversation.id, user_id) do
      {:ok, _} ->
        send(self(), {:conversation_deleted, "Conversation deleted"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not delete conversation"})
        {:noreply, socket}
    end
  end

  def handle_event("show_add_participants", _params, socket) do
    send(self(), {:show_add_participants})
    {:noreply, socket}
  end

  def handle_event("hide_add_participants", _params, socket) do
    send(self(), {:hide_add_participants})
    {:noreply, socket}
  end

  def handle_event("toggle_new_participant_selection", %{"friend_id" => friend_id}, socket) do
    friend_id = String.to_integer(friend_id)
    send(self(), {:toggle_new_participant_selection, friend_id})
    {:noreply, socket}
  end

  def handle_event("add_participants", _params, socket) do
    conversation = socket.assigns.active_conversation
    new_participant_ids = socket.assigns.selected_new_participants

    if new_participant_ids == [] do
      send(self(), {:error, "Please select at least one participant"})
      {:noreply, socket}
    else
      case Social.add_participants_to_conversation(conversation.id, new_participant_ids) do
        {:ok, _} ->
          send(self(), {:participants_added, conversation.id, "Participants added!"})
          {:noreply, socket}

        {:error, _} ->
          send(self(), {:error, "Could not add participants"})
          {:noreply, socket}
      end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[600px]">
      <!-- Conversations List -->
      <div class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="flex items-center justify-between mb-4">
            <h2 class="card-title">Conversations</h2>
            <button
              class="btn btn-primary btn-sm"
              phx-click="show_new_conversation_form"
              phx-target={@myself}
            >
              New Chat
            </button>
          </div>
          
    <!-- New Conversation Form -->
          <div :if={@show_new_conversation_form} class="mb-4 p-4 bg-base-200 rounded-lg">
            <form phx-submit="create_conversation" phx-target={@myself}>
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
                        phx-target={@myself}
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
                    phx-target={@myself}
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
                if(@active_conversation && @active_conversation.id == conversation.id,
                  do: "bg-primary text-primary-content",
                  else: "bg-base-200"
                )
              ]}
              phx-click="open_conversation"
              phx-value-conversation_id={conversation.id}
              phx-target={@myself}
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
          <div
            :if={@active_conversation == nil}
            class="flex-1 flex items-center justify-center text-center text-base-content/60"
          >
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
                phx-target={@myself}
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
                  phx-target={@myself}
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
                    phx-target={@myself}
                  >
                    Edit
                  </button>
                </div>

                <div :if={@editing_conversation_name}>
                  <form phx-submit="update_conversation_name" phx-target={@myself}>
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
                        phx-target={@myself}
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
                  <span class="text-sm font-medium">
                    Participants ({length(@active_conversation.participants)})
                  </span>
                  <button
                    class="btn btn-primary btn-xs"
                    phx-click="show_add_participants"
                    phx-target={@myself}
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
                      :if={
                        participant.id != @current_user_id &&
                          length(@active_conversation.participants) > 2
                      }
                      class="btn btn-error btn-xs"
                      phx-click="remove_participant"
                      phx-value-user_id={participant.id}
                      phx-target={@myself}
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
                      phx-target={@myself}
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
                        phx-target={@myself}
                        checked={friend.id in @selected_new_participants}
                      />
                      <span>{friend.email}</span>
                    </label>
                  </div>

                  <button
                    class="btn btn-primary btn-xs w-full"
                    phx-click="add_participants"
                    phx-target={@myself}
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
                  phx-target={@myself}
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
              <div
                :for={message <- @active_conversation.messages}
                class="p-3 bg-base-100 rounded-lg shadow-sm"
              >
                <div class="flex items-center justify-between text-xs text-base-content/60 mb-1">
                  <span>{message.user.email}</span>
                  <span>
                    {Calendar.strftime(
                      DateTime.add(message.inserted_at, -5, :hour),
                      "%m/%d %I:%M %p"
                    )}
                  </span>
                </div>
                <div class="text-sm">{message.content}</div>
              </div>
            </div>
            
    <!-- Message Input -->
            <form
              phx-submit="send_message"
              phx-change="update_message"
              phx-target={@myself}
              class="flex space-x-2 flex-shrink-0"
            >
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
    """
  end
end
