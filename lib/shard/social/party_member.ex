defmodule Shard.Social.PartyMember do
  @moduledoc """
  Creates the schema for party members, like who's in a party
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Users.User
  alias Shard.Social.Party

  schema "party_members" do
    belongs_to :party, Party
    belongs_to :user, User
    field :joined_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(party_member, attrs) do
    party_member
    |> cast(attrs, [:party_id, :user_id, :joined_at])
    |> validate_required([:party_id, :user_id, :joined_at])
    |> foreign_key_constraint(:party_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:party_id, :user_id])
  end
end
