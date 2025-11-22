defmodule Shard.Repo.Migrations.AddItemStatsSupport do
  use Ecto.Migration

  def change do
    # Create items table with comprehensive schema including weapon and armor stats
    create_if_not_exists table(:items) do
      add :name, :string, null: false
      add :description, :text
      add :item_type, :string, null: false
      add :rarity, :string, default: "common"
      add :value, :integer, default: 0
      add :weight, :decimal, precision: 8, scale: 2, default: 0.0
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

      timestamps(type: :utc_datetime)
    end

    # Add unique constraint on name
    create_if_not_exists unique_index(:items, [:name])

    # Add indexes for better performance when querying by item type and stats
    create index(:items, [:item_type])
    create index(:items, [:rarity])
    create index(:items, [:equippable])
    create index(:items, [:equipment_slot])
    create index(:items, [:value])

    # Add a regular GIN index for the stats JSONB column for efficient stat queries
    create index(:items, [:stats], using: :gin)

    # Add a GIN index for the effects JSONB column for efficient effect queries
    create index(:items, [:effects], using: :gin)

    # Add a GIN index for the requirements JSONB column for efficient requirement queries
    create index(:items, [:requirements], using: :gin)
  end
end
