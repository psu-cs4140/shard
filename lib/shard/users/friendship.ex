defmodule Shard.Users.Friendship do
  @moduledoc """
  Creates the schema for the friendships database table.  
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Users.User

  schema "friendships" do
    belongs_to :user, User
    belongs_to :friend, User
    field :status, :string, default: "pending"

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(friendship, attrs) do
    friendship
    |> cast(attrs, [:user_id, :friend_id, :status])
    |> validate_required([:user_id, :friend_id, :status])
    |> validate_inclusion(:status, ["pending", "accepted", "declined"])
    |> validate_different_users()
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:friend_id)
    |> unique_constraint([:user_id, :friend_id])
  end

  defp validate_different_users(changeset) do
    user_id = get_field(changeset, :user_id)
    friend_id = get_field(changeset, :friend_id)

    if user_id && friend_id && user_id == friend_id do
      add_error(changeset, :friend_id, "cannot be the same as user")
    else
      changeset
    end
  end
end
