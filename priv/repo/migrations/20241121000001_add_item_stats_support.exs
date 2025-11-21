defmodule Shard.Repo.Migrations.AddItemStatsSupport do
  use Ecto.Migration

  def change do
    # Add indexes for better performance when querying by item type and stats
    create_if_not_exists index(:items, [:item_type])
    create_if_not_exists index(:items, [:equippable])
    create_if_not_exists index(:items, [:equipment_slot])

    # Add a regular GIN index for the stats JSONB column (without CONCURRENTLY)
    create_if_not_exists index(:items, [:stats], using: :gin)
  end
end
