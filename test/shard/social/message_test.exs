defmodule Shard.Social.MessageTest do
  use Shard.DataCase

  alias Shard.Social.Message

  describe "changeset/2" do
    @valid_attrs %{
      content: "Hello, this is a test message!",
      conversation_id: 1,
      user_id: 1
    }

    test "changeset with valid attributes" do
      changeset = Message.changeset(%Message{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires content, conversation_id, and user_id" do
      changeset = Message.changeset(%Message{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.content
      assert "can't be blank" in errors.conversation_id
      assert "can't be blank" in errors.user_id
    end

    test "validates content length" do
      # Too short
      short_attrs = %{@valid_attrs | content: ""}
      changeset = Message.changeset(%Message{}, short_attrs)
      refute changeset.valid?
      assert %{content: ["can't be blank"]} = errors_on(changeset)

      # Too long
      long_content = String.duplicate("a", 1001)
      long_attrs = %{@valid_attrs | content: long_content}
      changeset = Message.changeset(%Message{}, long_attrs)
      refute changeset.valid?
      assert %{content: ["should be at most 1000 character(s)"]} = errors_on(changeset)
    end

    test "accepts valid content lengths" do
      # Minimum length
      attrs = %{@valid_attrs | content: "a"}
      changeset = Message.changeset(%Message{}, attrs)
      assert changeset.valid?

      # Maximum length
      max_content = String.duplicate("a", 1000)
      attrs = %{@valid_attrs | content: max_content}
      changeset = Message.changeset(%Message{}, attrs)
      assert changeset.valid?
    end

    test "validates foreign key constraints are present" do
      changeset = Message.changeset(%Message{}, @valid_attrs)
      
      # Check that foreign key constraints are present
      assert Enum.any?(changeset.constraints, fn constraint ->
        constraint.type == :foreign_key and constraint.field == :conversation_id
      end)
      
      assert Enum.any?(changeset.constraints, fn constraint ->
        constraint.type == :foreign_key and constraint.field == :user_id
      end)
    end

    test "accepts multiline content" do
      multiline_content = "This is line 1\nThis is line 2\nThis is line 3"
      attrs = %{@valid_attrs | content: multiline_content}
      changeset = Message.changeset(%Message{}, attrs)
      assert changeset.valid?
    end

    test "accepts content with special characters" do
      special_content = "Hello! How are you? 😊 Check this out: https://example.com"
      attrs = %{@valid_attrs | content: special_content}
      changeset = Message.changeset(%Message{}, attrs)
      assert changeset.valid?
    end
  end
end
