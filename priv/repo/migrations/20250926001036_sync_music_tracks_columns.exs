defmodule Shard.Repo.Migrations.SyncMusicTracksColumns do
  use Ecto.Migration

  # Using raw SQL with IF NOT EXISTS so it's idempotent across dev machines.
  def up do
    execute("""
    ALTER TABLE music_tracks
      ADD COLUMN IF NOT EXISTS key               text,
      ADD COLUMN IF NOT EXISTS title             text,
      ADD COLUMN IF NOT EXISTS artist            text,
      ADD COLUMN IF NOT EXISTS license           text,
      ADD COLUMN IF NOT EXISTS source            text,
      ADD COLUMN IF NOT EXISTS file              text,
      ADD COLUMN IF NOT EXISTS duration_seconds  integer,
      ADD COLUMN IF NOT EXISTS public            boolean DEFAULT TRUE
    """)

    execute("""
    CREATE UNIQUE INDEX IF NOT EXISTS music_tracks_key_index
      ON music_tracks (key) WHERE key IS NOT NULL
    """)
  end

  def down do
    # Keep it simple for dev: we won't drop columns on down.
    :ok
  end
end
