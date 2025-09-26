defmodule Shard.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Users.{User, UserToken, UserNotifier}

  ## ─────────────────────────── Database getters ───────────────────────────

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.
  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user. Raises if not found.
  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Returns all users.
  """
  def list_users, do: Repo.all(User)

  ## ─────────────────────────── User registration ──────────────────────────

  @doc """
  Registers a user.

  If `:password` is provided, it will be validated and hashed.
  Otherwise, registration is email-only (compatible with magic-link flow).
  """
  def register_user(attrs) when is_map(attrs) do
    changeset =
      if Map.has_key?(attrs, :password) or Map.has_key?(attrs, "password") do
        User.registration_changeset(%User{}, attrs)
      else
        User.email_changeset(%User{}, attrs)
      end

    Repo.insert(changeset)
  end

  ## ────────────────────────────── Settings ────────────────────────────────

  @doc """
  Returns true if the user is in sudo mode (recent auth within `minutes`, default 20 minutes).
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Shard.Users.User.email_changeset/3` for options.
  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using a token. If the token matches, updates email and deletes related tokens.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns a changeset for changing the user password.

  See `Shard.Users.User.password_changeset/3` for options.
  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password and expires all tokens (including sessions).
  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## ─────────────────────── Preferences (music toggle) ─────────────────────

  @doc """
  Returns a changeset for changing user preferences (e.g., `music_enabled`).
  """
  def change_user_preferences(%User{} = user, attrs \\ %{}) do
    User.settings_changeset(user, attrs)
  end

  @doc """
  Updates user preferences in the DB.
  """
  def update_user_preferences(%User{} = user, attrs) do
    user
    |> User.settings_changeset(attrs)
    |> Repo.update()
  end

  ## ─────────────────────────── Admin functionality ────────────────────────

  @doc """
  Grants admin privileges to a user.
  """
  def grant_admin(%User{} = user) do
    user
    |> User.admin_changeset(%{admin: true})
    |> Repo.update()
  end

  ## ─────────────────────────────── Session ────────────────────────────────

  @doc """
  Generates and stores a session token; returns the raw token.
  """
  def generate_user_session_token(%User{} = user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user (and optionally token metadata) by a signed session token.

  Return shape depends on `verify_session_token_query/1` (usually `{user, token_inserted_at}` or just `user`).
  """
  def get_user_by_session_token(token) when is_binary(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed session token.
  """
  def delete_user_session_token(token) when is_binary(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## ────────────────────────── Magic link (email) ──────────────────────────

  @doc """
  Gets the user by a magic link token.
  """
  def get_user_by_magic_link_token(token) when is_binary(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  Cases:
  1) User already confirmed: logs in and expires the magic link.
  2) User unconfirmed and no password: confirms, logs in, and expires all tokens.
  3) User unconfirmed with a password set: disallowed (prevents security pitfalls).
  """
  def login_user_by_magic_link(token) when is_binary(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      {%User{confirmed_at: nil, hashed_password: hash}, _} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        Please see the "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.
  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")
    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  ## ─────────────────────────── Token helper ───────────────────────────────

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
