defmodule Shard.Users.UserTest do
  use Shard.DataCase

  alias Shard.Users.User

  describe "valid_password?/2" do
    test "returns false for user without hashed password" do
      user = %User{}
      assert User.valid_password?(user, "password") == false
    end

    test "returns false for nil user" do
      assert User.valid_password?(nil, "password") == false
    end
  end

  describe "confirm_changeset/1" do
    test "sets confirmed_at to current time" do
      user = %User{}
      changeset = User.confirm_changeset(user)

      assert changeset.changes[:confirmed_at]
      assert DateTime.diff(changeset.changes[:confirmed_at], DateTime.utc_now(:second)) <= 1
    end
  end
end
