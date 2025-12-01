defmodule ShardWeb.FriendsLive.PartyTab do
  use ShardWeb, :live_component

  alias Shard.Social

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("create_party", _params, socket) do
    user_id = socket.assigns.current_user_id

    case Social.create_party(user_id) do
      {:ok, party} ->
        send(self(), {:party_created, party, "Party created!"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not create party"})
        {:noreply, socket}
    end
  end

  def handle_event("leave_party", _params, socket) do
    user_id = socket.assigns.current_user_id

    case Social.leave_party(user_id) do
      {:ok, _} ->
        send(self(), {:party_left, "Left party"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not leave party"})
        {:noreply, socket}
    end
  end

  def handle_event("invite_to_party", %{"friend_id" => friend_id}, socket) do
    user_id = socket.assigns.current_user_id
    friend_id = String.to_integer(friend_id)

    case Social.invite_to_party(user_id, friend_id) do
      {:ok, _} ->
        send(self(), {:party_invitation_sent, "Party invitation sent!"})
        {:noreply, socket}

      {:error, :friend_already_in_party} ->
        send(self(), {:error, "Friend is already in a party"})
        {:noreply, socket}

      {:error, :invitation_already_sent} ->
        send(self(), {:error, "Invitation already sent to this friend"})
        {:noreply, socket}

      {:error, :not_party_leader} ->
        send(self(), {:error, "Only the party leader can invite members"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not send party invitation"})
        {:noreply, socket}
    end
  end

  def handle_event("disband_party", _params, socket) do
    user_id = socket.assigns.current_user_id

    case Social.disband_party(user_id) do
      {:ok, _} ->
        send(self(), {:party_disbanded, "Party disbanded"})
        {:noreply, socket}

      {:error, :not_party_leader} ->
        send(self(), {:error, "Only the party leader can disband the party"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not disband party"})
        {:noreply, socket}
    end
  end

  def handle_event("kick_from_party", %{"member_id" => member_id}, socket) do
    user_id = socket.assigns.current_user_id
    member_id = String.to_integer(member_id)

    case Social.kick_from_party(user_id, member_id) do
      {:ok, _} ->
        send(self(), {:party_member_kicked, "Member removed from party"})
        {:noreply, socket}

      {:error, :not_party_leader} ->
        send(self(), {:error, "Only the party leader can remove members"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not remove member from party"})
        {:noreply, socket}
    end
  end

  def handle_event("accept_party_invitation", %{"invitation_id" => invitation_id}, socket) do
    case Social.accept_party_invitation(String.to_integer(invitation_id)) do
      {:ok, _} ->
        send(self(), {:party_invitation_accepted, "Party invitation accepted!"})
        {:noreply, socket}

      {:error, :already_in_party} ->
        send(self(), {:error, "You are already in a party"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not accept party invitation"})
        {:noreply, socket}
    end
  end

  def handle_event("decline_party_invitation", %{"invitation_id" => invitation_id}, socket) do
    case Social.decline_party_invitation(String.to_integer(invitation_id)) do
      {:ok, _} ->
        send(self(), {:party_invitation_declined, "Party invitation declined"})
        {:noreply, socket}

      {:error, _} ->
        send(self(), {:error, "Could not decline party invitation"})
        {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- Pending Party Invitations -->
      <div :if={@pending_party_invitations != []} class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <h2 class="card-title">Party Invitations</h2>
          <div class="space-y-2">
            <div
              :for={invitation <- @pending_party_invitations}
              class="flex items-center justify-between p-2 bg-base-200 rounded"
            >
              <div class="flex items-center space-x-3">
                <div class="avatar placeholder">
                  <div class="bg-neutral text-neutral-content rounded-full w-8">
                    <span class="text-xs">{String.first(invitation.inviter.email)}</span>
                  </div>
                </div>
                <div>
                  <span class="font-medium">{invitation.inviter.email}</span>
                  <p class="text-sm text-base-content/60">invited you to join their party</p>
                </div>
              </div>
              <div class="space-x-2">
                <button
                  class="btn btn-success btn-sm"
                  phx-click="accept_party_invitation"
                  phx-value-invitation_id={invitation.id}
                  phx-target={@myself}
                >
                  Accept
                </button>
                <button
                  class="btn btn-error btn-sm"
                  phx-click="decline_party_invitation"
                  phx-value-invitation_id={invitation.id}
                  phx-target={@myself}
                >
                  Decline
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div :if={@party == nil} class="card bg-base-100 shadow-xl">
        <div class="card-body text-center">
          <h2 class="card-title">No Party</h2>
          <p>You're not currently in a party.</p>
          <div class="card-actions justify-center">
            <button class="btn btn-primary" phx-click="create_party" phx-target={@myself}>
              Create Party
            </button>
          </div>
        </div>
      </div>

      <div :if={@party != nil} class="card bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="flex items-center justify-between">
            <h2 class="card-title">Your Party</h2>
            <div class="space-x-2">
              <button
                :if={@party.leader_id == @current_user_id}
                class="btn btn-warning btn-sm"
                phx-click="disband_party"
                phx-target={@myself}
              >
                Disband Party
              </button>
              <button class="btn btn-error btn-sm" phx-click="leave_party" phx-target={@myself}>
                Leave Party
              </button>
            </div>
          </div>

          <div class="space-y-2 mb-4">
            <div
              :for={member <- @party.party_members}
              class="flex items-center justify-between p-2 bg-base-200 rounded"
            >
              <div class="flex items-center space-x-3">
                <div class="avatar placeholder">
                  <div class="bg-neutral text-neutral-content rounded-full w-8">
                    <span class="text-xs">
                      {if member.user.id == @current_user_id,
                        do: "Y",
                        else: String.first(member.user.email)}
                    </span>
                  </div>
                </div>
                <span>
                  {if member.user.id == @current_user_id, do: "You", else: member.user.email}
                </span>
                <span :if={member.user.id == @party.leader_id} class="badge badge-warning">
                  Leader
                </span>
              </div>
              <button
                :if={
                  @party.leader_id == @current_user_id &&
                    member.user.id != @current_user_id
                }
                class="btn btn-error btn-xs"
                phx-click="kick_from_party"
                phx-value-member_id={member.user.id}
                phx-target={@myself}
              >
                Kick
              </button>
            </div>
          </div>
          
          <!-- Invite Friends Section (only for party leader) -->
          <div :if={@party.leader_id == @current_user_id} class="border-t pt-4">
            <!-- Pending Invitations -->
            <div :if={@sent_party_invitations != []} class="mb-4">
              <h3 class="font-semibold mb-3">Pending Invitations</h3>
              <div class="space-y-2">
                <div
                  :for={invitation <- @sent_party_invitations}
                  class="flex items-center justify-between p-2 bg-yellow-50 border border-yellow-200 rounded"
                >
                  <div class="flex items-center space-x-3">
                    <div class="avatar placeholder">
                      <div class="bg-neutral text-neutral-content rounded-full w-8">
                        <span class="text-xs">{String.first(invitation.invitee.email)}</span>
                      </div>
                    </div>
                    <span>{invitation.invitee.email}</span>
                  </div>
                  <span class="badge badge-warning">Pending</span>
                </div>
              </div>
            </div>

            <h3 class="font-semibold mb-3">Invite Friends</h3>
            <div :if={@friends == []} class="text-center text-base-content/60 py-4">
              No friends available to invite.
            </div>
            <div :if={@friends != []} class="space-y-2">
              <div
                :for={friend_data <- @friends}
                :if={friend_data.friend.id not in Enum.map(@party.party_members, & &1.user.id)}
                class="flex items-center justify-between p-2 bg-base-100 rounded"
              >
                <div class="flex items-center space-x-3">
                  <div class="avatar placeholder">
                    <div class="bg-neutral text-neutral-content rounded-full w-8">
                      <span class="text-xs">{String.first(friend_data.friend.email)}</span>
                    </div>
                  </div>
                  <span>{friend_data.friend.email}</span>
                </div>
                <div :if={friend_data.in_party} class="badge badge-neutral">
                  In Party, Can't Invite
                </div>
                <div :if={!friend_data.in_party}>
                  <div
                    :if={
                      friend_data.friend.id in Enum.map(@sent_party_invitations, & &1.invitee.id)
                    }
                    class="badge badge-warning"
                  >
                    Pending
                  </div>
                  <button
                    :if={
                      friend_data.friend.id not in Enum.map(
                        @sent_party_invitations,
                        & &1.invitee.id
                      )
                    }
                    class="btn btn-primary btn-sm"
                    phx-click="invite_to_party"
                    phx-value-friend_id={friend_data.friend.id}
                    phx-target={@myself}
                  >
                    Invite
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
