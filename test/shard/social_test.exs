defmodule Shard.SocialTest do
  use Shard.DataCase

  alias Shard.Social
  alias Shard.Social.{Conversation, ConversationParticipant, Message}
  import Shard.UsersFixtures

  describe "conversations" do
    @invalid_attrs %{title: nil}

    test "create_conversation/1 with valid data creates a conversation" do
      user1 = user_fixture()
      user2 = user_fixture()
      
      attrs = %{
        title: "Test Conversation",
        participant_ids: [user1.id, user2.id]
      }

      assert {:ok, %Conversation{} = conversation} = Social.create_conversation(attrs)
      assert conversation.title == "Test Conversation"
    end

    test "create_conversation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Social.create_conversation(@invalid_attrs)
    end

    test "list_user_conversations/1 returns conversations for user" do
      user1 = user_fixture()
      user2 = user_fixture()
      
      {:ok, conversation} = Social.create_conversation(%{
        title: "Test Conversation",
        participant_ids: [user1.id, user2.id]
      })

      conversations = Social.list_user_conversations(user1.id)
      assert length(conversations) >= 1
      assert Enum.any?(conversations, fn c -> c.id == conversation.id end)
    end

    test "get_conversation!/1 returns the conversation with given id" do
      user1 = user_fixture()
      user2 = user_fixture()
      
      {:ok, conversation} = Social.create_conversation(%{
        title: "Test Conversation",
        participant_ids: [user1.id, user2.id]
      })

      assert Social.get_conversation!(conversation.id).id == conversation.id
    end

    test "delete_conversation/1 deletes the conversation" do
      user1 = user_fixture()
      user2 = user_fixture()
      
      {:ok, conversation} = Social.create_conversation(%{
        title: "Test Conversation",
        participant_ids: [user1.id, user2.id]
      })

      assert {:ok, %Conversation{}} = Social.delete_conversation(conversation)
      assert_raise Ecto.NoResultsError, fn -> Social.get_conversation!(conversation.id) end
    end
  end

  describe "messages" do
    setup do
      user1 = user_fixture()
      user2 = user_fixture()
      
      {:ok, conversation} = Social.create_conversation(%{
        title: "Test Conversation",
        participant_ids: [user1.id, user2.id]
      })

      %{user1: user1, user2: user2, conversation: conversation}
    end

    test "create_message/1 with valid data creates a message", %{user1: user1, conversation: conversation} do
      attrs = %{
        content: "Hello, world!",
        conversation_id: conversation.id,
        user_id: user1.id
      }

      assert {:ok, %Message{} = message} = Social.create_message(attrs)
      assert message.content == "Hello, world!"
      assert message.conversation_id == conversation.id
      assert message.user_id == user1.id
    end

    test "create_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Social.create_message(%{})
    end

    test "list_conversation_messages/1 returns messages for conversation", %{user1: user1, conversation: conversation} do
      {:ok, message} = Social.create_message(%{
        content: "Test message",
        conversation_id: conversation.id,
        user_id: user1.id
      })

      messages = Social.list_conversation_messages(conversation.id)
      assert length(messages) >= 1
      assert Enum.any?(messages, fn m -> m.id == message.id end)
    end

    test "get_message!/1 returns the message with given id", %{user1: user1, conversation: conversation} do
      {:ok, message} = Social.create_message(%{
        content: "Test message",
        conversation_id: conversation.id,
        user_id: user1.id
      })

      assert Social.get_message!(message.id).id == message.id
    end

    test "update_message/2 with valid data updates the message", %{user1: user1, conversation: conversation} do
      {:ok, message} = Social.create_message(%{
        content: "Original message",
        conversation_id: conversation.id,
        user_id: user1.id
      })

      update_attrs = %{content: "Updated message"}

      assert {:ok, %Message{} = message} = Social.update_message(message, update_attrs)
      assert message.content == "Updated message"
    end

    test "delete_message/1 deletes the message", %{user1: user1, conversation: conversation} do
      {:ok, message} = Social.create_message(%{
        content: "Test message",
        conversation_id: conversation.id,
        user_id: user1.id
      })

      assert {:ok, %Message{}} = Social.delete_message(message)
      assert_raise Ecto.NoResultsError, fn -> Social.get_message!(message.id) end
    end
  end

  describe "conversation participants" do
    setup do
      user1 = user_fixture()
      user2 = user_fixture()
      
      {:ok, conversation} = Social.create_conversation(%{
        title: "Test Conversation",
        participant_ids: [user1.id, user2.id]
      })

      %{user1: user1, user2: user2, conversation: conversation}
    end

    test "add_participant/2 adds user to conversation", %{conversation: conversation} do
      user3 = user_fixture()

      assert {:ok, %ConversationParticipant{}} = Social.add_participant(conversation.id, user3.id)
      
      participants = Social.list_conversation_participants(conversation.id)
      assert length(participants) == 3
      assert Enum.any?(participants, fn p -> p.user_id == user3.id end)
    end

    test "remove_participant/2 removes user from conversation", %{user1: user1, conversation: conversation} do
      assert {:ok, _} = Social.remove_participant(conversation.id, user1.id)
      
      participants = Social.list_conversation_participants(conversation.id)
      assert length(participants) == 1
      refute Enum.any?(participants, fn p -> p.user_id == user1.id end)
    end

    test "list_conversation_participants/1 returns all participants", %{user1: user1, user2: user2, conversation: conversation} do
      participants = Social.list_conversation_participants(conversation.id)
      assert length(participants) == 2
      
      user_ids = Enum.map(participants, & &1.user_id)
      assert user1.id in user_ids
      assert user2.id in user_ids
    end

    test "mark_as_read/2 updates last_read_at", %{user1: user1, conversation: conversation} do
      assert {:ok, %ConversationParticipant{}} = Social.mark_as_read(conversation.id, user1.id)
      
      participant = Social.get_participant(conversation.id, user1.id)
      assert participant.last_read_at != nil
    end
  end

  describe "Message changeset" do
    test "validates required fields" do
      changeset = Message.changeset(%Message{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.content
      assert "can't be blank" in errors.conversation_id
      assert "can't be blank" in errors.user_id
    end

    test "validates content length" do
      attrs = %{
        content: String.duplicate("a", 1001),
        conversation_id: 1,
        user_id: 1
      }

      changeset = Message.changeset(%Message{}, attrs)
      refute changeset.valid?
      assert %{content: ["should be at most 1000 character(s)"]} = errors_on(changeset)
    end

    test "validates minimum content length" do
      attrs = %{
        content: "",
        conversation_id: 1,
        user_id: 1
      }

      changeset = Message.changeset(%Message{}, attrs)
      refute changeset.valid?
      assert %{content: ["should be at least 1 character(s)"]} = errors_on(changeset)
    end

    test "accepts valid message data" do
      attrs = %{
        content: "Valid message content",
        conversation_id: 1,
        user_id: 1
      }

      changeset = Message.changeset(%Message{}, attrs)
      assert changeset.valid?
    end
  end

  describe "ConversationParticipant changeset" do
    test "validates required fields" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.conversation_id
      assert "can't be blank" in errors.user_id
    end

    test "accepts valid participant data" do
      attrs = %{
        conversation_id: 1,
        user_id: 1,
        last_read_at: DateTime.utc_now()
      }

      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, attrs)
      assert changeset.valid?
    end
  end
end
