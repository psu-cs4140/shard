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
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    # For magic link tests, we need users without passwords
    # Check if password should be nil for magic link compatibility
    attrs = 
      if Map.get(attrs, :password) == nil do
        attrs
        |> valid_user_attributes()
        |> Map.delete(:password)
      else
        attrs
        |> valid_user_attributes()
      end

    {:ok, user} = Users.register_user(attrs)
    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)

    # Directly confirm the user instead of using magic link
    # since magic links don't work with password-based users
    {:ok, confirmed_user} =
      user
      |> Shard.Users.User.confirm_changeset()
      |> Shard.Repo.update()

    confirmed_user
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
end
