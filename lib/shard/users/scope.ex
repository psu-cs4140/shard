defmodule Shard.Users.Scope do
  @moduledoc """
  A small container for the authenticated user and the time they re-authenticated
  (used for ‘sudo mode’ checks).
  """

  alias Shard.Users.User

  @enforce_keys [:user]
  defstruct [:user, :authenticated_at]

  @type t :: %__MODULE__{
          user: User.t(),
          authenticated_at: DateTime.t() | NaiveDateTime.t() | nil
        }

  @doc "Build a new scope."
  @spec new(User.t(), DateTime.t() | NaiveDateTime.t() | nil) :: t()
  def new(%User{} = user, authenticated_at \\ nil) do
    %__MODULE__{user: user, authenticated_at: authenticated_at}
  end

  @doc """
  Normalize a few common shapes into a %Scope{}.

  * `%User{}` → `%Scope{user: user}`
  * `{%User{}, dt}` → `%Scope{user: user, authenticated_at: dt}`
  * `%Scope{}` → passthrough
  * anything else → `nil`
  """
  @spec normalize(any) :: t() | nil
  def normalize(%__MODULE__{} = scope), do: scope
  def normalize(%User{} = user), do: new(user)
  def normalize({%User{} = user, dt}), do: new(user, dt)
  def normalize(_), do: nil

  @doc """
  Back-compat shim for older call sites & tests.

  Equivalent to `normalize(user)`.
  """
  @spec for_user(User.t() | nil) :: t() | nil
  def for_user(nil), do: nil
  def for_user(%User{} = user), do: new(user)
end
