defmodule Shard.Repo.Migrations.CreateFriendships do
  use Ecto.Migration

  def change do
    execute """
    CREATE TABLE IF NOT EXISTS friendships (
      id bigserial PRIMARY KEY,
      user_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      friend_id bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      status varchar(255) DEFAULT 'pending' NOT NULL,
      inserted_at timestamp(0) NOT NULL,
      updated_at timestamp(0) NOT NULL,
      CONSTRAINT no_self_friendship CHECK (user_id != friend_id)
    )
    """, "DROP TABLE IF EXISTS friendships"

    execute "CREATE INDEX IF NOT EXISTS friendships_user_id_index ON friendships (user_id)", 
            "DROP INDEX IF EXISTS friendships_user_id_index"
    
    execute "CREATE INDEX IF NOT EXISTS friendships_friend_id_index ON friendships (friend_id)", 
            "DROP INDEX IF EXISTS friendships_friend_id_index"
    
    execute "CREATE UNIQUE INDEX IF NOT EXISTS friendships_user_id_friend_id_index ON friendships (user_id, friend_id)", 
            "DROP INDEX IF EXISTS friendships_user_id_friend_id_index"
  end
end
