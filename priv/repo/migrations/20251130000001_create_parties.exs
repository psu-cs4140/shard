defmodule Shard.Repo.Migrations.CreateParties do
  use Ecto.Migration

  def change do
    execute """
    CREATE TABLE IF NOT EXISTS parties (
      id bigserial PRIMARY KEY,
      name varchar(255),
      leader_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      max_size integer DEFAULT 6,
      inserted_at timestamp(0) NOT NULL,
      updated_at timestamp(0) NOT NULL
    )
    """, "DROP TABLE IF EXISTS parties"

    execute "CREATE INDEX IF NOT EXISTS parties_leader_id_index ON parties (leader_id)", 
            "DROP INDEX IF EXISTS parties_leader_id_index"

    execute """
    CREATE TABLE IF NOT EXISTS party_members (
      id bigserial PRIMARY KEY,
      party_id bigint NOT NULL REFERENCES parties(id) ON DELETE CASCADE,
      user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      joined_at timestamp(0) NOT NULL,
      inserted_at timestamp(0) NOT NULL,
      updated_at timestamp(0) NOT NULL
    )
    """, "DROP TABLE IF EXISTS party_members"

    execute "CREATE INDEX IF NOT EXISTS party_members_party_id_index ON party_members (party_id)", 
            "DROP INDEX IF EXISTS party_members_party_id_index"
    
    execute "CREATE INDEX IF NOT EXISTS party_members_user_id_index ON party_members (user_id)", 
            "DROP INDEX IF EXISTS party_members_user_id_index"
    
    execute "CREATE UNIQUE INDEX IF NOT EXISTS party_members_party_id_user_id_index ON party_members (party_id, user_id)", 
            "DROP INDEX IF EXISTS party_members_party_id_user_id_index"
  end
end
