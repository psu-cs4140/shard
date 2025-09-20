defmodule Shard.UsersFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Shard.Users` context.
  """

  import Ecto.Query

  alias Shard.Users
  alias Shard.Users.Scope

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Users.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    token =
      extract_user_token(fn url ->
        Users.deliver_login_instructions(user, url)
      end)

    {:ok, {user, _expired_tokens}} =
      Users.login_user_by_magic_link(token)

    user
  end

  def user_scope_fixture do
    user = user_fixture()
    user_scope_fixture(user)
  end

  def user_scope_fixture(user) do
    Scope.for_user(user)
  end

  def set_password(user) do
    {:ok, {user, _expired_tokens}} =
      Users.update_user_password(user, %{password: valid_user_password()})

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  def override_token_authenticated_at(token, authenticated_at) when is_binary(token) do
    Shard.Repo.update_all(
      from(t in Users.UserToken,
        where: t.token == ^token
      ),
      set: [authenticated_at: authenticated_at]
    )
  end

  def generate_user_magic_link_token(user) do
    {encoded_token, user_token} = Users.UserToken.build_email_token(user, "login")
    Shard.Repo.insert!(user_token)
    {encoded_token, user_token.token}
  end

  def offset_user_token(token, amount_to_add, unit) do
    dt = DateTime.add(DateTime.utc_now(:second), amount_to_add, unit)

    Shard.Repo.update_all(
      from(ut in Users.UserToken, where: ut.token == ^token),
      set: [inserted_at: dt, authenticated_at: dt]
    )
  end

  @doc """
  Generate multiple users.
  """
  def users_fixture(count, attrs \\ %{}) do
    for _ <- 1..count do
      user_fixture(attrs)
    end
  end

  @doc """
  Generate an admin user.
  """
  def admin_user_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)
    
    {:ok, user} = 
      user
      |> Users.change_user()
      |> Users.User.admin_changeset(%{admin: true})
      |> Shard.Repo.update()
    
    user
  end

  @doc """
  Generate a confirmed user with password set.
  """
  def confirmed_user_with_password_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)
    set_password(user)
  end

  @doc """
  Generate multiple confirmed users with passwords.
  """
  def confirmed_users_with_passwords_fixture(count, attrs \\ %{}) do
    for _ <- 1..count do
      confirmed_user_with_password_fixture(attrs)
    end
  end
end
