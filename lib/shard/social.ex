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
      select: p
    )
    |> Repo.one()
    |> case do
      nil -> nil
      party -> 
        party
        |> Repo.preload(party_members: :user)
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

  def invite_to_party(leader_id, friend_id) do
    case get_user_party(leader_id) do
      nil -> {:error, :not_in_party}
      party ->
        # Check if user is the party leader
        if party.leader_id != leader_id do
          {:error, :not_party_leader}
        else
          # Check if friend is already in a party
          case get_user_party(friend_id) do
            nil ->
              # Friend is not in a party, add them
              %PartyMember{}
              |> PartyMember.changeset(%{
                party_id: party.id,
                user_id: friend_id,
                joined_at: DateTime.utc_now()
              })
              |> Repo.insert()
            
            _existing_party ->
              {:error, :friend_already_in_party}
          end
        end
    end
  end

  def disband_party(leader_id) do
    case get_user_party(leader_id) do
      nil -> {:error, :not_in_party}
      party ->
        if party.leader_id != leader_id do
          {:error, :not_party_leader}
        else
          Repo.transaction(fn ->
            # Delete all party members
            from(pm in PartyMember, where: pm.party_id == ^party.id)
            |> Repo.delete_all()
            
            # Delete the party
            Repo.delete!(party)
          end)
        end
    end
  end

  def kick_from_party(leader_id, member_id) do
    case get_user_party(leader_id) do
      nil -> {:error, :not_in_party}
      party ->
        if party.leader_id != leader_id do
          {:error, :not_party_leader}
        else
          # Cannot kick yourself
          if leader_id == member_id do
            {:error, :cannot_kick_self}
          else
            # Check if member is actually in the party
            case Repo.get_by(PartyMember, party_id: party.id, user_id: member_id) do
              nil -> {:error, :member_not_in_party}
              member -> Repo.delete(member)
            end
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

  def find_existing_conversation(participant_ids) do
    participant_count = length(participant_ids)
    
    # Find conversations where all participants match exactly
    from(c in Conversation,
      join: cp in ConversationParticipant,
      on: cp.conversation_id == c.id,
      where: cp.user_id in ^participant_ids,
      group_by: c.id,
      having: count(cp.user_id) == ^participant_count,
      select: c
    )
    |> Repo.all()
    |> Enum.find(fn conversation ->
      # Double-check that the conversation has exactly the same participants
      conversation_participant_ids = 
        from(cp in ConversationParticipant,
          where: cp.conversation_id == ^conversation.id,
          select: cp.user_id
        )
        |> Repo.all()
        |> Enum.sort()
      
      Enum.sort(participant_ids) == conversation_participant_ids
    end)
  end

  def create_conversation(user_ids, attrs \\ %{}) do
    case Repo.transaction(fn ->
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
         end) do
      {:ok, conversation} ->
        # Notify all participants about the new conversation
        Enum.each(user_ids, fn user_id ->
          Phoenix.PubSub.broadcast(
            Shard.PubSub,
            "user:#{user_id}:conversations",
            {:conversation_created, conversation}
          )
        end)
        
        {:ok, conversation}
      
      error ->
        error
    end
  end

  def update_conversation_name(conversation_id, name) do
    conversation = Repo.get!(Conversation, conversation_id)
    
    conversation
    |> Conversation.changeset(%{name: name})
    |> Repo.update()
  end

  def delete_conversation(conversation_id, user_id) do
    conversation = Repo.get!(Conversation, conversation_id)
    
    # Check if user is a participant
    participant = Repo.get_by(ConversationParticipant, conversation_id: conversation_id, user_id: user_id)
    
    if participant do
      Repo.transaction(fn ->
        # Delete all messages
        from(m in Message, where: m.conversation_id == ^conversation_id)
        |> Repo.delete_all()
        
        # Delete all participants
        from(cp in ConversationParticipant, where: cp.conversation_id == ^conversation_id)
        |> Repo.delete_all()
        
        # Delete conversation
        Repo.delete!(conversation)
      end)
    else
      {:error, :not_participant}
    end
  end

  def add_participants_to_conversation(conversation_id, user_ids) do
    Repo.transaction(fn ->
      Enum.each(user_ids, fn user_id ->
        # Check if user is already a participant
        existing = Repo.get_by(ConversationParticipant, conversation_id: conversation_id, user_id: user_id)
        
        unless existing do
          %ConversationParticipant{}
          |> ConversationParticipant.changeset(%{
            conversation_id: conversation_id,
            user_id: user_id
          })
          |> Repo.insert!()
        end
      end)
      
      # Notify new participants
      Enum.each(user_ids, fn user_id ->
        Phoenix.PubSub.broadcast(
          Shard.PubSub,
          "user:#{user_id}:conversations",
          {:conversation_created, Repo.get!(Conversation, conversation_id)}
        )
      end)
    end)
  end

  def remove_participant_from_conversation(conversation_id, user_id) do
    participant = Repo.get_by(ConversationParticipant, conversation_id: conversation_id, user_id: user_id)
    
    if participant do
      # Check if this would leave less than 2 participants
      remaining_count = 
        from(cp in ConversationParticipant, where: cp.conversation_id == ^conversation_id)
        |> Repo.aggregate(:count, :id)
      
      if remaining_count <= 2 do
        {:error, :minimum_participants}
      else
        Repo.delete(participant)
      end
    else
      {:error, :not_participant}
    end
  end

  def send_message(conversation_id, user_id, content) do
    case %Message{}
         |> Message.changeset(%{
           conversation_id: conversation_id,
           user_id: user_id,
           content: content
         })
         |> Repo.insert() do
      {:ok, message} ->
        # Broadcast the new message to all participants in the conversation
        Phoenix.PubSub.broadcast(
          Shard.PubSub,
          "conversation:#{conversation_id}",
          {:new_message, conversation_id}
        )
        
        {:ok, message}
      
      error ->
        error
    end
  end
end
