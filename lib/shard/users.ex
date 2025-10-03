defmodule Shard.Users do
  @moduledoc """
  The Users context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset
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
    if user && User.valid_password?(user, password), do: user
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
  Returns true if the user is in sudo mode (recent auth within `minutes`, default 10 minutes).
  """
  def sudo_mode?(user, minutes \\ 10)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, NaiveDateTime) do
    # If your schema uses NaiveDateTime:
    fresh_cutoff = NaiveDateTime.add(NaiveDateTime.utc_now(), -minutes * 60, :second)
    NaiveDateTime.compare(ts, fresh_cutoff) == :gt
  end

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    # If your schema uses DateTime:
    DateTime.after?(ts, DateTime.add(DateTime.utc_now(), -minutes * 60, :second))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  Adds a specific validation so submitting the same email yields the error text
  "did not change" (expected by tests).
  """
  def change_user_email(%User{} = user, attrs \\ %{}, _opts \\ []) do
    user
    |> change()
    |> cast(attrs, [:email])
    |> validate_required([:email])
    |> validate_change(:email, fn :email, new ->
      if new == user.email, do: [email: "did not change"], else: []
    end)
  end

  @doc """
  Updates the user email using a token. If the token matches, updates email and deletes related tokens.
  """
  def update_user_email(%User{} = user, token) when is_binary(token) do
    context = "change:#{user.email}"

    Repo.transaction(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_, _} <-
             Repo.delete_all(
               from t in UserToken,
                 where: t.user_id == ^user.id and t.context == ^context
             ) do
        {:ok, user}
      else
        _ -> Repo.rollback(:invalid_token)
      end
    end)
    |> case do
      {:ok, {:ok, user}} -> {:ok, user}
      {:error, _} -> {:error, :invalid_token}
      other -> other
    end
  end

  @doc """
  Returns a changeset for changing the user password.

  Wrapper provided for compatibility; delegates to the schema changeset.
  """
  def change_user_password(%User{} = user, attrs \\ %{}, _opts \\ []) do
    User.password_changeset(user, attrs)
  end

  @doc """
  Updates the user password and expires all tokens (including sessions).

  Returns `{:ok, user}` on success (note: not a tuple of `{user, tokens}`),
  matching what LiveView tests expect.
  """
  def update_user_password(%User{} = user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## ────────────────────────────── Helpers ─────────────────────────────────

  # Update user with given changeset and delete all of the user's tokens/sessions.
  defp update_user_and_delete_all_tokens(%Ecto.Changeset{} = changeset) do
    Repo.transaction(fn ->
      case Repo.update(changeset) do
        {:ok, user} ->
          # Delete all contexts (sessions, reset, confirm, etc.)
          Repo.delete_all(UserToken.user_and_contexts_query(user))
          {:ok, user}

        {:error, reason} ->
          Repo.rollback(reason)
      end
    end)
    |> case do
      {:ok, {:ok, user}} -> {:ok, user}
      {:error, reason} -> {:error, reason}
      other -> other
    end
  end
end
