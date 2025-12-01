defmodule Shard.Repo.Migrations.CreateConversations do
  use Ecto.Migration

  def change do
    execute """
    CREATE TABLE IF NOT EXISTS conversations (
      id bigserial PRIMARY KEY,
      name varchar(255),
      type varchar(255) DEFAULT 'direct' NOT NULL,
      inserted_at timestamp(0) NOT NULL,
      updated_at timestamp(0) NOT NULL
    )
    """, "DROP TABLE IF EXISTS conversations"

    execute """
    CREATE TABLE IF NOT EXISTS conversation_participants (
      id bigserial PRIMARY KEY,
      conversation_id bigint NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
      user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      last_read_at timestamp(0),
      inserted_at timestamp(0) NOT NULL,
      updated_at timestamp(0) NOT NULL
    )
    """, "DROP TABLE IF EXISTS conversation_participants"

    execute "CREATE INDEX IF NOT EXISTS conversation_participants_conversation_id_index ON conversation_participants (conversation_id)", 
            "DROP INDEX IF EXISTS conversation_participants_conversation_id_index"
    
    execute "CREATE INDEX IF NOT EXISTS conversation_participants_user_id_index ON conversation_participants (user_id)", 
            "DROP INDEX IF EXISTS conversation_participants_user_id_index"
    
    execute "CREATE UNIQUE INDEX IF NOT EXISTS conversation_participants_conversation_id_user_id_index ON conversation_participants (conversation_id, user_id)", 
            "DROP INDEX IF EXISTS conversation_participants_conversation_id_user_id_index"

    execute """
    CREATE TABLE IF NOT EXISTS messages (
      id bigserial PRIMARY KEY,
      conversation_id bigint NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
      user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      content text NOT NULL,
      inserted_at timestamp(0) NOT NULL,
      updated_at timestamp(0) NOT NULL
    )
    """, "DROP TABLE IF EXISTS messages"

    execute "CREATE INDEX IF NOT EXISTS messages_conversation_id_index ON messages (conversation_id)", 
            "DROP INDEX IF EXISTS messages_conversation_id_index"
    
    execute "CREATE INDEX IF NOT EXISTS messages_user_id_index ON messages (user_id)", 
            "DROP INDEX IF EXISTS messages_user_id_index"
    
    execute "CREATE INDEX IF NOT EXISTS messages_inserted_at_index ON messages (inserted_at)", 
            "DROP INDEX IF EXISTS messages_inserted_at_index"
  end
end
