defmodule Shard.Repo.Migrations.CreateZones do
  use Ecto.Migration

  def change do
    create table(:zones) do
      add :name, :string, null: false
      add :zone_id, :string, null: false
      add :slug, :string, null: false
      add :description, :text
      add :zone_type, :string, default: "standard", null: false
      add :min_level, :integer, default: 1, null: false
      add :max_level, :integer
      add :is_public, :boolean, default: true, null: false
      add :is_active, :boolean, default: true, null: false
      add :properties, :map, default: "{}", null: false
      add :display_order, :integer, default: 0, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:zones, [:zone_id])
    create unique_index(:zones, [:zone_id])
    create unique_index(:zones, [:slug])
    create index(:zones, [:name])
    create index(:zones, [:zone_type])
    create index(:zones, [:is_active])
    create index(:zones, [:display_order])
  end
end
