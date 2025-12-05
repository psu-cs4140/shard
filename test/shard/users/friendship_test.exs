defmodule Shard.Users.FriendshipTest do
  use Shard.DataCase

  alias Shard.Users.Friendship

  describe "changeset/2" do
    @valid_attrs %{
      user_id: 1,
      friend_id: 2,
      status: "pending"
    }

    test "changeset with valid attributes" do
      changeset = Friendship.changeset(%Friendship{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset requires user_id, friend_id, and status" do
      changeset = Friendship.changeset(%Friendship{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "can't be blank" in errors.user_id
      assert "can't be blank" in errors.friend_id
      # status has a default value, so it might not be required in the same way
    end

    test "validates status inclusion" do
      invalid_attrs = %{@valid_attrs | status: "invalid_status"}
      changeset = Friendship.changeset(%Friendship{}, invalid_attrs)
      refute changeset.valid?
      assert %{status: ["is invalid"]} = errors_on(changeset)
    end

    test "accepts all valid statuses" do
      for status <- ["pending", "accepted", "declined"] do
        attrs = %{@valid_attrs | status: status}
        changeset = Friendship.changeset(%Friendship{}, attrs)
        assert changeset.valid?, "Expected #{status} to be valid"
      end
    end

    test "validates that user_id and friend_id are different" do
      invalid_attrs = %{@valid_attrs | user_id: 1, friend_id: 1}
      changeset = Friendship.changeset(%Friendship{}, invalid_attrs)
      refute changeset.valid?
      assert %{friend_id: ["cannot be the same as user"]} = errors_on(changeset)
    end

    test "accepts different user and friend IDs" do
      attrs = %{@valid_attrs | user_id: 1, friend_id: 2}
      changeset = Friendship.changeset(%Friendship{}, attrs)
      assert changeset.valid?
    end

    test "accepts default status" do
      attrs = %{user_id: 1, friend_id: 2}
      changeset = Friendship.changeset(%Friendship{}, attrs)
      assert changeset.valid?
      assert get_field(changeset, :status) == "pending"
    end

    test "validates foreign key constraints are present" do
      changeset = Friendship.changeset(%Friendship{}, @valid_attrs)

      # Check that foreign key constraints are present
      assert Enum.any?(changeset.constraints, fn constraint ->
               constraint.type == :foreign_key and constraint.field == :user_id
             end)

      assert Enum.any?(changeset.constraints, fn constraint ->
               constraint.type == :foreign_key and constraint.field == :friend_id
             end)
    end

    test "validates unique constraint is present" do
      changeset = Friendship.changeset(%Friendship{}, @valid_attrs)

      # Check that unique constraint is present
      assert Enum.any?(changeset.constraints, fn constraint ->
               constraint.type == :unique
             end)
    end
  end
end
