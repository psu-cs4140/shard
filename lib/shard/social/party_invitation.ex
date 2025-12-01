defmodule Shard.Social.PartyInvitation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "party_invitations" do
    field :status, :string, default: "pending"
    belongs_to :party, Shard.Social.Party
    belongs_to :inviter, Shard.Users.User
    belongs_to :invitee, Shard.Users.User

    timestamps()
  end

  @doc false
  def changeset(party_invitation, attrs) do
    party_invitation
    |> cast(attrs, [:party_id, :inviter_id, :invitee_id, :status])
    |> validate_required([:party_id, :inviter_id, :invitee_id])
    |> validate_inclusion(:status, ["pending", "accepted", "declined"])
    |> unique_constraint([:party_id, :invitee_id], name: :party_invitations_party_id_invitee_id_index)
  end
end
