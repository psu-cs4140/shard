defmodule Shard.Repo.Migrations.AddItemStatsSupport do
  use Ecto.Migration

  def change do
    # Add indexes for better performance when querying by item type and stats
    create_if_not_exists index(:items, [:item_type])
    create_if_not_exists index(:items, [:equippable])
    create_if_not_exists index(:items, [:equipment_slot])
    create_if_not_exists index(:items, [:rarity])
    create_if_not_exists index(:items, [:value])

    # Add a regular GIN index for the stats JSONB column for efficient stat queries
    create_if_not_exists index(:items, [:stats], using: :gin)

    # Add a GIN index for the effects JSONB column for efficient effect queries
    create_if_not_exists index(:items, [:effects], using: :gin)

    # Add a GIN index for the requirements JSONB column for efficient requirement queries
    create_if_not_exists index(:items, [:requirements], using: :gin)
  end
end
