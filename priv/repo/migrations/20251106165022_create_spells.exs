defmodule Shard.Repo.Migrations.CreateSpells do
  use Ecto.Migration

  def change do
    create table(:spells) do
      add :name, :string, null: false
      add :description, :string
      add :mana_cost, :integer, default: 0
      add :damage, :integer
      add :healing, :integer
      add :level_required, :integer, default: 1
      add :spell_type_id, references(:spell_types, on_delete: :nothing)
      add :spell_effect_id, references(:spell_effects, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:spells, [:spell_type_id])
    create index(:spells, [:spell_effect_id])
    create unique_index(:spells, [:name])
  end
end
