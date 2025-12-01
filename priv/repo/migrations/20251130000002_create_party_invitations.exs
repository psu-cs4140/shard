defmodule Shard.Repo.Migrations.CreatePartyInvitations do
  use Ecto.Migration

  def change do
    execute """
            CREATE TABLE IF NOT EXISTS party_invitations (
              id bigserial PRIMARY KEY,
              status varchar(255) DEFAULT 'pending' NOT NULL,
              party_id bigint NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
              inviter_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              invitee_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
              inserted_at timestamp(0) NOT NULL,
              updated_at timestamp(0) NOT NULL
            )
            """,
            "DROP TABLE IF EXISTS party_invitations"

    execute "CREATE INDEX IF NOT EXISTS party_invitations_party_id_index ON party_invitations (party_id)",
            "DROP INDEX IF EXISTS party_invitations_party_id_index"

    execute "CREATE INDEX IF NOT EXISTS party_invitations_inviter_id_index ON party_invitations (inviter_id)",
            "DROP INDEX IF EXISTS party_invitations_inviter_id_index"

    execute "CREATE INDEX IF NOT EXISTS party_invitations_invitee_id_index ON party_invitations (invitee_id)",
            "DROP INDEX IF EXISTS party_invitations_invitee_id_index"

    execute "CREATE UNIQUE INDEX IF NOT EXISTS party_invitations_party_id_invitee_id_index ON party_invitations (party_id, invitee_id)",
            "DROP INDEX IF EXISTS party_invitations_party_id_invitee_id_index"
  end
end
