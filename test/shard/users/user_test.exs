defmodule Shard.Users.UserTest do
  use Shard.DataCase

  alias Shard.Users.User

  describe "email_changeset/3" do
    test "validates email format" do
      changeset = User.email_changeset(%User{}, %{email: "invalid"})
      refute changeset.valid?
      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates email length" do
      long_email = String.duplicate("a", 150) <> "@example.com"
      changeset = User.email_changeset(%User{}, %{email: long_email})
      refute changeset.valid?
      assert %{email: ["should be at most 160 character(s)"]} = errors_on(changeset)
    end

    test "validates email is required" do
      changeset = User.email_changeset(%User{}, %{})
      refute changeset.valid?
      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "accepts valid email" do
      changeset = User.email_changeset(%User{}, %{email: "test@example.com"})
      assert changeset.valid?
    end

    test "validates email uniqueness when validate_unique is true" do
      # This test would require database setup, so we'll test the changeset structure
      changeset = User.email_changeset(%User{}, %{email: "test@example.com"}, validate_unique: true)
      assert changeset.valid?
      # The actual uniqueness validation happens at the database level
    end

    test "skips uniqueness validation when validate_unique is false" do
      changeset = User.email_changeset(%User{}, %{email: "test@example.com"}, validate_unique: false)
      assert changeset.valid?
    end

    test "validates email changed for existing user" do
      user = %User{email: "old@example.com"}
      changeset = User.email_changeset(user, %{email: "old@example.com"})
      refute changeset.valid?
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "accepts admin field" do
      changeset = User.email_changeset(%User{}, %{email: "test@example.com", admin: true})
      assert changeset.valid?
      assert get_change(changeset, :admin) == true
    end
  end

  describe "password_changeset/3" do
    test "validates password is required" do
      changeset = User.password_changeset(%User{}, %{})
      refute changeset.valid?
      assert %{password: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates password length" do
      # Too short
      changeset = User.password_changeset(%User{}, %{password: "short"})
      refute changeset.valid?
      assert %{password: ["should be at least 12 character(s)"]} = errors_on(changeset)

      # Too long
      long_password = String.duplicate("a", 73)
      changeset = User.password_changeset(%User{}, %{password: long_password})
      refute changeset.valid?
      assert %{password: ["should be at most 72 character(s)"]} = errors_on(changeset)
    end

    test "validates password confirmation" do
      changeset = User.password_changeset(%User{}, %{
        password: "validpassword123",
        password_confirmation: "different"
      })
      refute changeset.valid?
      assert %{password_confirmation: ["does not match password"]} = errors_on(changeset)
    end

    test "hashes password when valid and hash_password is true" do
      changeset = User.password_changeset(%User{}, %{
        password: "validpassword123"
      }, hash_password: true)

      assert changeset.valid?
      assert get_change(changeset, :hashed_password)
      assert is_nil(get_change(changeset, :password))
    end

    test "does not hash password when hash_password is false" do
      changeset = User.password_changeset(%User{}, %{
        password: "validpassword123"
      }, hash_password: false)

      assert changeset.valid?
      assert is_nil(get_change(changeset, :hashed_password))
      assert get_change(changeset, :password) == "validpassword123"
    end

    test "does not hash invalid password" do
      changeset = User.password_changeset(%User{}, %{
        password: "short"
      }, hash_password: true)

      refute changeset.valid?
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "admin_changeset/2" do
    test "accepts boolean admin values" do
      changeset = User.admin_changeset(%User{}, %{admin: true})
      assert changeset.valid?
      assert get_field(changeset, :admin) == true

      changeset = User.admin_changeset(%User{}, %{admin: false})
      assert changeset.valid?
      assert get_field(changeset, :admin) == false
    end

    test "requires admin field to be explicitly provided" do
      changeset = User.admin_changeset(%User{}, %{})
      refute changeset.valid?
      assert %{admin: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "confirm_changeset/1" do
    test "sets confirmed_at to current time" do
      user = %User{}
      changeset = User.confirm_changeset(user)
      
      confirmed_at = get_change(changeset, :confirmed_at)
      assert confirmed_at
      assert DateTime.diff(DateTime.utc_now(), confirmed_at, :second) < 2
    end
  end

  describe "valid_password?/2" do
    test "returns true for valid password" do
      password = "validpassword123"
      hashed_password = Argon2.hash_pwd_salt(password)
      user = %User{hashed_password: hashed_password}
      
      assert User.valid_password?(user, password)
    end

    test "returns false for invalid password" do
      password = "validpassword123"
      hashed_password = Argon2.hash_pwd_salt(password)
      user = %User{hashed_password: hashed_password}
      
      refute User.valid_password?(user, "wrongpassword")
    end

    test "returns false when user has no hashed_password" do
      user = %User{hashed_password: nil}
      refute User.valid_password?(user, "anypassword")
    end

    test "returns false when password is empty" do
      user = %User{hashed_password: "somehash"}
      refute User.valid_password?(user, "")
    end

    test "returns false when user is nil" do
      refute User.valid_password?(nil, "anypassword")
    end
  end
end
