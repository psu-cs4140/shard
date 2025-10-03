defmodule Shard.Repo.Migrations.AddKeyRequiredToDoors do
  use Ecto.Migration

  def up do
    execute """
    ALTER TABLE doors
      ADD COLUMN IF NOT EXISTS key_required boolean NOT NULL DEFAULT false
    """
  end

  def down do
    execute """
    ALTER TABLE doors
      DROP COLUMN IF EXISTS key_required
    """
  end
end
