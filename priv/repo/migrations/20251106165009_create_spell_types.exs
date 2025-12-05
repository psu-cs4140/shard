defmodule Shard.Repo.Migrations.CreateSpellTypes do
  use Ecto.Migration

  def change do
    create table(:spell_types) do
      add :name, :string, null: false
      add :description, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:spell_types, [:name])
  end
end
