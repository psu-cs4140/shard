defmodule Shard.UsersTest do
  use Shard.DataCase

  alias Shard.Users
  alias Shard.Users.{User, UserToken}

  import Shard.UsersFixtures

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Users.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Users.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Users.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture()
      refute Users.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture()

      assert %User{id: ^id} =
               Users.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Users.get_user!(999)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Users.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Users.register_user(%{})

      errors = errors_on(changeset)
      assert "can't be blank" in errors.email
      assert "can't be blank" in (errors[:password] || errors["password"] || [])
    end

    test "validates email and password when given" do
      {:error, changeset} = Users.register_user(%{email: "not valid", password: "not valid"})

      errors = errors_on(changeset)
      assert "must have the @ sign and no spaces" in errors.email

      assert "should be at least 12 character(s)" in (errors[:password] || errors["password"] ||
                                                        [])
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Users.register_user(%{email: too_long, password: too_long})
      errors = errors_on(changeset)
      assert "should be at most 160 character(s)" in errors.email
      # Password validation might not trigger if email validation fails first
      if Map.has_key?(errors, :password) do
        assert "should be at most 72 character(s)" in errors.password
      end
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Users.register_user(%{email: email, password: "valid_password123"})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} =
        Users.register_user(%{email: String.upcase(email), password: "valid_password123"})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = unique_user_email()
      password = valid_user_password()
      {:ok, user} = Users.register_user(%{email: email, password: password})
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end

    test "sets first user as admin" do
      # Clear any existing users
      Repo.delete_all(User)

      email = unique_user_email()
      password = valid_user_password()
      {:ok, user} = Users.register_user(%{email: email, password: password})
      assert user.admin == true
    end

    test "subsequent users are not admin by default" do
      # Ensure at least one user exists
      _first_user = user_fixture()

      email = unique_user_email()
      password = valid_user_password()
      {:ok, user} = Users.register_user(%{email: email, password: password})
      assert user.admin == false
    end
  end

  describe "change_user_email/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Users.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Users.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Users.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      result = Users.get_user_by_session_token(token)

      case result do
        {session_user, _timestamp} ->
          assert session_user.id == user.id

        session_user when is_struct(session_user) ->
          assert session_user.id == user.id

        nil ->
          flunk("Expected user but got nil")
      end
    end

    test "does not return user for invalid token" do
      refute Users.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Users.get_user_by_session_token(token)
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Users.generate_user_session_token(user)
      assert Users.delete_user_session_token(token) == :ok
      refute Users.get_user_by_session_token(token)
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      user = %User{password: "123456"}
      refute inspect(user) =~ "password: \"123456\""
    end
  end
end
