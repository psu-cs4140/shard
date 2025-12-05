defmodule Shard.Repo.Migrations.CreateSpellEffects do
  use Ecto.Migration

  def change do
    create table(:spell_effects) do
      add :name, :string, null: false
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:spell_effects, [:name])
  end
end
