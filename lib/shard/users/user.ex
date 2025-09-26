defmodule Shard.Users.User do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc false

  # don't leak secrets in logs/inspects
  @derive {Inspect, except: [:password, :password_confirmation, :hashed_password]}

  @email_regex ~r/^[^\s]+@[^\s]+$/

  # ── Schema ──────────────────────────────────────────────────────────────
  schema "users" do
    field :email, :string
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime
    field :admin, :boolean, default: false

    # Feature toggles / auth helpers
    field :music_enabled, :boolean, default: false
    field :authenticated_at, :utc_datetime

    # Virtuals for forms
    field :password, :string, virtual: true
    field :password_confirmation, :string, virtual: true

    # Useful if your tokens table belongs_to :user
    has_many :tokens, Shard.Users.UserToken

    timestamps()
  end

  # ── Registration / update changesets ────────────────────────────────────

  @doc """
  Registration for new users — requires password and hashes it.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password, :password_confirmation])
    |> email_validations()
    |> password_validations(hash_password?: true, required?: true)
  end

  @doc """
  General update (safe default). Password is optional here.
  Set `hash_password?: true` when you expect to update the password.
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :password,
      :password_confirmation,
      :admin,
      :confirmed_at,
      :music_enabled
    ])
    |> email_validations()
    |> password_validations(hash_password?: true, required?: false)
  end

  # ── Settings (music checkbox) ───────────────────────────────────────────

  @doc """
  Settings/preferences form — currently just :music_enabled.
  """
  def settings_changeset(user, attrs) do
    user
    |> cast(attrs, [:music_enabled])
    |> validate_required([:music_enabled])
  end

  # Back-compat alias (some code may call preferences_changeset/2)
  def preferences_changeset(user, attrs), do: settings_changeset(user, attrs)

  # ── Email changesets used by Shard.Users ────────────────────────────────

  def email_changeset(user, attrs), do: email_changeset(user, attrs, [])

  def email_changeset(user, attrs, _opts) do
    user
    |> cast(attrs, [:email])
    |> email_validations()
  end

  # ── Password changesets used by Shard.Users ─────────────────────────────

  def password_changeset(user, attrs), do: password_changeset(user, attrs, [])

  def password_changeset(user, attrs, opts) do
    hash? = Keyword.get(opts, :hash_password, true)
    required? = Keyword.get(opts, :require_password, true)

    user
    |> cast(attrs, [:password, :password_confirmation])
    |> password_validations(hash_password?: hash?, required?: required?)
  end

  # ── Admin toggle used by Shard.Users.grant_admin/1 ──────────────────────

  def admin_changeset(user, attrs) do
    user
    |> cast(attrs, [:admin])
    |> validate_required([:admin])
  end

  # ── Email confirmation used by magic-link flows ─────────────────────────

  def confirm_changeset(user) do
    change(user, confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second))
  end

  # ── Auth helpers used by Shard.Users ────────────────────────────────────

  def valid_password?(%__MODULE__{hashed_password: hash}, password)
      when is_binary(hash) and is_binary(password) and byte_size(password) > 0 do
    Argon2.verify_pass(password, hash)
  end

  def valid_password?(_user, _password) do
    Argon2.no_user_verify()
    false
  end

  # If you want to stamp last-authenticated time from the context:
  def mark_authenticated_changeset(user) do
    change(user, authenticated_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  # ── Private helpers ─────────────────────────────────────────────────────

  defp email_validations(changeset) do
    changeset
    |> update_change(:email, fn
      nil -> nil
      e -> e |> String.trim() |> String.downcase()
    end)
    |> validate_required([:email])
    |> validate_length(:email, max: 160)
    |> validate_format(:email, @email_regex)
    |> unsafe_validate_unique(:email, Shard.Repo)
    |> unique_constraint(:email)
  end

  defp password_validations(changeset, opts) do
    required? = Keyword.get(opts, :required?, Keyword.get(opts, :required, false))
    hash? = Keyword.get(opts, :hash_password?, Keyword.get(opts, :hash_password, true))

    changeset
    |> then(fn cs -> if required?, do: validate_required(cs, [:password]), else: cs end)
    |> validate_length(:password, min: 12, max: 72)
    |> validate_confirmation(:password, required: required?)
    |> maybe_put_hashed_password(hash?)
  end

  defp maybe_put_hashed_password(changeset, true) do
    case get_change(changeset, :password) do
      pw when is_binary(pw) and byte_size(pw) > 0 ->
        changeset
        |> put_change(:hashed_password, Argon2.hash_pwd_salt(pw))
        |> delete_change(:password)
        |> delete_change(:password_confirmation)

      _ ->
        changeset
    end
  end

  defp maybe_put_hashed_password(changeset, false), do: changeset
end
