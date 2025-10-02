defmodule Shard.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
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

    create unique_index(:items, [:name])
    create index(:items, [:item_type])
    create index(:items, [:rarity])
  end
end
