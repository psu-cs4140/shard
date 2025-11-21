defmodule Shard.Repo.Migrations.AddItemStatsSupport do
  use Ecto.Migration

  def change do
    # Ensure the stats column exists and is properly typed
    alter table(:items) do
      # The stats column should already exist as :map from the original schema
      # This migration ensures it's properly set up if needed
      modify :stats, :map, default: "{}"
    end

    # Add indexes for better performance when querying by item type and stats
    create index(:items, [:item_type])
    create index(:items, [:equippable])
    create index(:items, [:equipment_slot])
    
    # Add a GIN index for the stats JSONB column for efficient stat queries
    execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS items_stats_gin_index ON items USING GIN (stats)", 
            "DROP INDEX IF EXISTS items_stats_gin_index"
  end
end
