defmodule Shard.Social.Party do
  @moduledoc """
  Creates the schema for a party.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Shard.Users.User
  alias Shard.Social.PartyMember

  schema "parties" do
    field :name, :string
    field :max_size, :integer, default: 6
    belongs_to :leader, User
    has_many :party_members, PartyMember
    has_many :members, through: [:party_members, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(party, attrs) do
    party
    |> cast(attrs, [:name, :leader_id, :max_size])
    |> validate_required([:leader_id])
    |> validate_number(:max_size, greater_than: 0, less_than_or_equal_to: 10)
    |> foreign_key_constraint(:leader_id)
  end
end
