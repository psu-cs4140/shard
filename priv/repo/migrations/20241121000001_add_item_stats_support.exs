defmodule Shard.Repo.Migrations.AddItemStatsSupport do
  use Ecto.Migration

  def change do
    # Add missing columns that aren't in the base items table
    alter table(:items) do
      add_if_not_exists :pickup, :boolean, default: true
      add_if_not_exists :location, :string
      add_if_not_exists :map, :string
      add_if_not_exists :sellable, :boolean, default: true
    end

    # Add indexes for better performance when querying by item type and stats
    create_if_not_exists index(:items, [:equippable])
    create_if_not_exists index(:items, [:equipment_slot])
    create_if_not_exists index(:items, [:value])

    # Add a regular GIN index for the stats JSONB column for efficient stat queries
    create_if_not_exists index(:items, [:stats], using: :gin)

    # Add a GIN index for the effects JSONB column for efficient effect queries
    create_if_not_exists index(:items, [:effects], using: :gin)

    # Add a GIN index for the requirements JSONB column for efficient requirement queries
    create_if_not_exists index(:items, [:requirements], using: :gin)
  end
end
