defmodule Shard.Social do
  @moduledoc """
  The Social context.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Users.{User, Friendship}
  alias Shard.Social.{Party, PartyMember, Conversation, ConversationParticipant, Message}

  # ───────────────────────── Friendships ─────────────────────────

  def list_friends(user_id) do
    from(f in Friendship,
      where: f.user_id == ^user_id and f.status == "accepted",
      join: u in User,
      on: u.id == f.friend_id,
      select: %{friendship: f, friend: u}
    )
    |> Repo.all()
  end

  def list_pending_friend_requests(user_id) do
    from(f in Friendship,
      where: f.friend_id == ^user_id and f.status == "pending",
      join: u in User,
      on: u.id == f.user_id,
      select: %{friendship: f, requester: u}
    )
    |> Repo.all()
  end

  def list_sent_friend_requests(user_id) do
    from(f in Friendship,
      where: f.user_id == ^user_id and f.status == "pending",
      join: u in User,
      on: u.id == f.friend_id,
      select: %{friendship: f, recipient: u}
    )
    |> Repo.all()
  end

  def search_users(query, current_user_id) when byte_size(query) >= 1 do
    # Get existing friend IDs to exclude them from search
    # This includes: friends, pending requests sent BY current user, pending requests sent TO current user
    existing_relationships = 
      from(f in Friendship,
        where: (f.user_id == ^current_user_id or f.friend_id == ^current_user_id) and f.status in ["pending", "accepted"],
        select: fragment("CASE WHEN ? = ? THEN ? ELSE ? END", f.user_id, ^current_user_id, f.friend_id, f.user_id)
      )
      |> Repo.all()

    excluded_ids = [current_user_id | existing_relationships]

    from(u in User,
      where: ilike(u.email, ^"%#{query}%") and u.id not in ^excluded_ids,
      limit: 10,
      order_by: u.email
    )
    |> Repo.all()
  end

  def search_users(_query, _current_user_id), do: []

  def send_friend_request(user_id, friend_id) do
    %Friendship{}
    |> Friendship.changeset(%{user_id: user_id, friend_id: friend_id, status: "pending"})
    |> Repo.insert()
  end

  def accept_friend_request(friendship_id) do
    friendship = Repo.get!(Friendship, friendship_id)
    
    Repo.transaction(fn ->
      # Accept the original request
      friendship
      |> Friendship.changeset(%{status: "accepted"})
      |> Repo.update!()

      # Check if reciprocal friendship already exists
      existing_reciprocal = 
        from(f in Friendship,
          where: f.user_id == ^friendship.friend_id and f.friend_id == ^friendship.user_id
        )
        |> Repo.one()

      case existing_reciprocal do
        nil ->
          # Create the reciprocal friendship
          %Friendship{}
          |> Friendship.changeset(%{
            user_id: friendship.friend_id,
            friend_id: friendship.user_id,
            status: "accepted"
          })
          |> Repo.insert!()
        
        existing ->
          # Update existing reciprocal friendship to accepted
          existing
          |> Friendship.changeset(%{status: "accepted"})
          |> Repo.update!()
      end
    end)
  end

  def decline_friend_request(friendship_id) do
    friendship = Repo.get!(Friendship, friendship_id)
    
    Repo.transaction(fn ->
      # Delete the original request
      Repo.delete!(friendship)
      
      # Also delete any reciprocal friendship if it exists
      from(f in Friendship,
        where: f.user_id == ^friendship.friend_id and f.friend_id == ^friendship.user_id
      )
      |> Repo.delete_all()
    end)
  end

  def remove_friend(user_id, friend_id) do
    Repo.transaction(fn ->
      # Remove both directions of the friendship
      from(f in Friendship,
        where: (f.user_id == ^user_id and f.friend_id == ^friend_id) or
               (f.user_id == ^friend_id and f.friend_id == ^user_id)
      )
      |> Repo.delete_all()
    end)
  end

  # ───────────────────────── Parties ─────────────────────────

  def get_user_party(user_id) do
    from(pm in PartyMember,
      where: pm.user_id == ^user_id,
      join: p in Party,
      on: p.id == pm.party_id,
      preload: [party: [party_members: :user]]
    )
    |> Repo.one()
    |> case do
      %{party: party} -> party
      nil -> nil
    end
  end

  def create_party(leader_id, attrs \\ %{}) do
    Repo.transaction(fn ->
      party =
        %Party{}
        |> Party.changeset(Map.put(attrs, :leader_id, leader_id))
        |> Repo.insert!()

      %PartyMember{}
      |> PartyMember.changeset(%{
        party_id: party.id,
        user_id: leader_id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert!()

      party
    end)
  end

  def leave_party(user_id) do
    case get_user_party(user_id) do
      nil -> {:error, :not_in_party}
      party ->
        member = Repo.get_by!(PartyMember, party_id: party.id, user_id: user_id)
        Repo.delete(member)
        
        # If leader left, disband party or transfer leadership
        if party.leader_id == user_id do
          remaining_members = 
            from(pm in PartyMember, where: pm.party_id == ^party.id)
            |> Repo.all()
            
          case remaining_members do
            [] -> Repo.delete(party)
            [new_leader | _] ->
              party
              |> Party.changeset(%{leader_id: new_leader.user_id})
              |> Repo.update()
          end
        end
    end
  end

  # ───────────────────────── Conversations ─────────────────────────

  def list_user_conversations(user_id) do
    from(cp in ConversationParticipant,
      where: cp.user_id == ^user_id,
      join: c in Conversation,
      on: c.id == cp.conversation_id,
      preload: [conversation: [:participants]]
    )
    |> Repo.all()
    |> Enum.map(& &1.conversation)
  end

  def get_conversation_with_messages(conversation_id) do
    from(c in Conversation,
      where: c.id == ^conversation_id,
      preload: [
        :participants,
        messages: :user
      ]
    )
    |> Repo.one()
  end

  def create_conversation(user_ids, attrs \\ %{}) do
    Repo.transaction(fn ->
      conversation =
        %Conversation{}
        |> Conversation.changeset(attrs)
        |> Repo.insert!()

      Enum.each(user_ids, fn user_id ->
        %ConversationParticipant{}
        |> ConversationParticipant.changeset(%{
          conversation_id: conversation.id,
          user_id: user_id
        })
        |> Repo.insert!()
      end)

      conversation
    end)
  end

  def send_message(conversation_id, user_id, content) do
    %Message{}
    |> Message.changeset(%{
      conversation_id: conversation_id,
      user_id: user_id,
      content: content
    })
    |> Repo.insert()
  end
end
