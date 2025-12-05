defmodule Shard.Social.ConversationParticipantTest do
  use Shard.DataCase

  alias Shard.Social.ConversationParticipant

  describe "changeset/2" do
    @valid_attrs %{
      conversation_id: 1,
      user_id: 1,
      last_read_at: DateTime.utc_now()
    }

    test "changeset with valid attributes" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires conversation_id and user_id" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.conversation_id
      assert "can't be blank" in errors.user_id
    end

    test "accepts optional last_read_at" do
      attrs = %{conversation_id: 1, user_id: 1}
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, attrs)
      assert changeset.valid?
    end

    test "accepts last_read_at timestamp" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      attrs = %{conversation_id: 1, user_id: 1, last_read_at: now}
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, attrs)
      assert changeset.valid?
      assert get_field(changeset, :last_read_at) == now
    end

    test "validates foreign key constraints are present" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, @valid_attrs)

      # Check that foreign key constraints are present
      assert Enum.any?(changeset.constraints, fn constraint ->
               constraint.type == :foreign_key and constraint.field == :conversation_id
             end)

      assert Enum.any?(changeset.constraints, fn constraint ->
               constraint.type == :foreign_key and constraint.field == :user_id
             end)
    end

    test "validates unique constraint is present" do
      changeset = ConversationParticipant.changeset(%ConversationParticipant{}, @valid_attrs)

      # Check that unique constraint is present
      assert Enum.any?(changeset.constraints, fn constraint ->
               constraint.type == :unique
             end)
    end
  end
end
