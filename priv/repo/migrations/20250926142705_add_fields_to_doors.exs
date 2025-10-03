defmodule Shard.Repo.Migrations.AddFieldsToDoors do
  use Ecto.Migration

  # Add only the new/missing columns. Using IF NOT EXISTS keeps this safe to re-run.
  def up do
    execute("""
    ALTER TABLE doors
      ADD COLUMN IF NOT EXISTS name        text,
      ADD COLUMN IF NOT EXISTS description text,
      ADD COLUMN IF NOT EXISTS door_type   varchar NOT NULL DEFAULT 'standard',
      ADD COLUMN IF NOT EXISTS properties  jsonb    NOT NULL DEFAULT '{}'::jsonb
    """)
  end

  def down do
    execute("""
    ALTER TABLE doors
      DROP COLUMN IF EXISTS properties,
      DROP COLUMN IF EXISTS door_type,
      DROP COLUMN IF EXISTS description,
      DROP COLUMN IF EXISTS name
    """)
  end
end
