defmodule Shard.Repo.Migrations.CreatePartyInvitationsTable do
  use Ecto.Migration

  def change do
    create table(:party_invitations, if_not_exists: true) do
      add :status, :string, default: "pending", null: false
      add :party_id, references(:parties, on_delete: :delete_all), null: false
      add :inviter_id, references(:users, on_delete: :delete_all), null: false
      add :invitee_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:party_invitations, [:party_id])
    create index(:party_invitations, [:inviter_id])
    create index(:party_invitations, [:invitee_id])

    create unique_index(:party_invitations, [:party_id, :invitee_id],
             name: :party_invitations_party_id_invitee_id_index
           )
  end
end
