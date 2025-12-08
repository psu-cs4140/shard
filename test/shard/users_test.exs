defmodule Shard.UsersTest do
  use Shard.DataCase

  alias Shard.Users
  alias Shard.Users.{User, UserZoneProgress}

  import Shard.UsersFixtures

  describe "users" do
    test "get_user_by_email/1 returns the user with given email" do
      user = user_fixture()
      assert Users.get_user_by_email(user.email).id == user.id
    end

    test "get_user_by_email/1 does not return the user if the email does not exist" do
      refute Users.get_user_by_email("unknown@example.com")
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Users.get_user!(user.id).id == user.id
    end

    test "register_user/1 with valid data creates a user" do
      valid_attrs = %{email: "test@example.com", password: "hello world!"}

      assert {:ok, %User{} = user} = Users.register_user(valid_attrs)
      assert user.email == "test@example.com"
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
    end

    test "register_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Users.register_user(%{})
    end

    test "register_user/1 registers users with a hashed password" do
      email = "test@example.com"
      valid_attrs = %{email: email, password: "hello world!"}

      assert {:ok, %User{} = user} = Users.register_user(valid_attrs)
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.password)
    end

    test "change_user_registration/1 returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Users.change_user_registration(%User{})
      assert changeset.required == [:password, :email]
    end

    test "change_user_email/1 returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Users.change_user_email(%User{})
      assert changeset.required == [:email]
    end

    test "apply_user_email/3 requires email to change" do
      user = user_fixture()

      assert Users.apply_user_email(user, "valid password", %{}) == {:error, %Ecto.Changeset{}}
    end

    test "apply_user_email/3 validates email" do
      user = user_fixture()

      assert Users.apply_user_email(user, "valid password", %{email: "not valid"}) ==
               {:error, %Ecto.Changeset{}}
    end

    test "apply_user_email/3 validates maximum value for email for security" do
      user = user_fixture()
      too_long = String.duplicate("db", 100)

      assert Users.apply_user_email(user, "valid password", %{email: too_long}) ==
               {:error, %Ecto.Changeset{}}
    end

    test "apply_user_email/3 validates email uniqueness" do
      user = user_fixture()
      %{email: email} = user_fixture()

      assert Users.apply_user_email(user, "valid password", %{email: email}) ==
               {:error, %Ecto.Changeset{}}
    end

    test "apply_user_email/3 validates current password" do
      user = user_fixture()

      assert Users.apply_user_email(user, "invalid", %{email: "new@example.com"}) ==
               {:error, %Ecto.Changeset{}}
    end

    test "apply_user_email/3 applies the email without persisting it" do
      user = user_fixture()
      email = "new@example.com"

      assert {:ok, %User{} = changed_user} =
               Users.apply_user_email(user, "valid password", %{email: email})

      assert changed_user.email == email
      assert Users.get_user!(user.id).email == user.email
    end
  end

  describe "user zone progress" do
    test "UserZoneProgress.for_user/1 returns progress for user" do
      user = user_fixture()
      progress = UserZoneProgress.for_user(user.id)
      assert is_list(progress)
    end

    test "UserZoneProgress.for_user/1 with nil returns nil" do
      assert UserZoneProgress.for_user(nil) == nil
    end
  end

  describe "user authentication" do
    test "valid_password?/2 validates password" do
      user = user_fixture()
      assert Users.valid_password?(user, "valid password") == true
      assert Users.valid_password?(user, "invalid") == false
    end

    test "valid_password?/2 with invalid user returns false" do
      assert Users.valid_password?(nil, "password") == false
    end
  end

  describe "user scope" do
    alias Shard.Users.Scope

    test "for_user/1 creates scope for user" do
      user = user_fixture()
      scope = Scope.for_user(user)
      assert %Scope{user: ^user} = scope
    end

    test "for_user/1 with nil returns nil" do
      assert Scope.for_user(nil) == nil
    end
  end
end
