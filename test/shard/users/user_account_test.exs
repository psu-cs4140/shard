defmodule Shard.Users.UserAccountTest do
  use Shard.DataCase

  alias Shard.Users
  alias Shard.Users.User

  import Shard.UsersFixtures

  describe "user account creation" do
    test "user exists after creating account" do
      email = unique_user_email()
      attrs = %{email: email, password: valid_user_password()}

      # Create the user account
      assert {:ok, user} = Users.register_user(attrs)

      # Verify the user actually exists in the database
      assert %User{} = Users.get_user!(user.id)
      assert Users.get_user_by_email(email) == user
    end

    test "user has correct attributes after creation" do
      email = unique_user_email()
      attrs = %{email: email, password: valid_user_password()}

      # Create the user account
      assert {:ok, user} = Users.register_user(attrs)

      # Verify the user has the expected attributes
      retrieved_user = Users.get_user!(user.id)
      assert retrieved_user.email == email
      assert retrieved_user.id == user.id
      assert is_nil(retrieved_user.confirmed_at)
    end

    test "first user is automatically admin" do
      # Clear any existing users to ensure this is the first
      Shard.Repo.delete_all(User)

      email = unique_user_email()
      attrs = %{email: email, password: valid_user_password()}

      # Create the first user
      assert {:ok, user} = Users.register_user(attrs)

      # Verify the first user is admin
      retrieved_user = Users.get_user!(user.id)
      assert retrieved_user.admin == true
    end

    test "second user is not automatically admin" do
      # Ensure there's already a user in the system
      _first_user = user_fixture()

      email = unique_user_email()
      attrs = %{email: email, password: valid_user_password()}

      # Create the second user
      assert {:ok, user} = Users.register_user(attrs)

      # Verify the second user is not admin
      retrieved_user = Users.get_user!(user.id)
      assert retrieved_user.admin == false
    end
  end
end
