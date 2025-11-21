defmodule Shard.Repo.Migrations.AddItemStatsSupport do
  use Ecto.Migration
  @disable_ddl_transaction true

  def change do
    # Create items table if it doesn't exist
    create_if_not_exists table(:items) do
      add :name, :string, null: false
      add :description, :text
      add :item_type, :string, null: false
      add :rarity, :string, default: "common"
      add :value, :integer, default: 0
      add :weight, :decimal, default: 0.0
      add :stackable, :boolean, default: false
      add :max_stack_size, :integer, default: 1
      add :usable, :boolean, default: false
      add :equippable, :boolean, default: false
      add :equipment_slot, :string
      add :stats, :map, default: %{}
      add :requirements, :map, default: %{}
      add :effects, :map, default: %{}
      add :icon, :string
      add :is_active, :boolean, default: true
      add :pickup, :boolean, default: true
      add :location, :string
      add :map, :string
      add :sellable, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    # Add unique constraint on name
    create_if_not_exists unique_index(:items, [:name])

    # Add indexes for better performance when querying by item type and stats
    create_if_not_exists index(:items, [:item_type])
    create_if_not_exists index(:items, [:equippable])
    create_if_not_exists index(:items, [:equipment_slot])

    # Add a GIN index for the stats JSONB column for efficient stat queries
    execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS items_stats_gin_index ON items USING GIN (stats)",
            "DROP INDEX IF EXISTS items_stats_gin_index"
  end
end
