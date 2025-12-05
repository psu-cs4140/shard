defmodule Shard.Social.ConversationTest do
  use Shard.DataCase

  alias Shard.Social.Conversation

  describe "changeset/2" do
    @valid_attrs %{
      name: "Test Conversation",
      type: "direct"
    }

    test "changeset with valid attributes" do
      changeset = Conversation.changeset(%Conversation{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset accepts optional name" do
      changeset = Conversation.changeset(%Conversation{}, %{type: "group"})
      assert changeset.valid?
    end

    test "validates type inclusion" do
      invalid_attrs = %{@valid_attrs | type: "invalid_type"}
      changeset = Conversation.changeset(%Conversation{}, invalid_attrs)
      refute changeset.valid?
      assert %{type: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts valid conversation types" do
      for type <- ["direct", "group"] do
        attrs = %{@valid_attrs | type: type}
        changeset = Conversation.changeset(%Conversation{}, attrs)
        assert changeset.valid?, "Expected #{type} to be valid"
      end
    end

    test "accepts default type" do
      changeset = Conversation.changeset(%Conversation{}, %{name: "Test"})
      assert changeset.valid?
      assert get_field(changeset, :type) == "direct"
    end

    test "accepts conversation without name" do
      changeset = Conversation.changeset(%Conversation{}, %{type: "direct"})
      assert changeset.valid?
    end
  end
end
