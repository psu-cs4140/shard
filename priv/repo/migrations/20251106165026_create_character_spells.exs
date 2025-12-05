defmodule Shard.Repo.Migrations.CreateCharacterSpells do
  use Ecto.Migration

  def change do
    create table(:character_spells) do
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :spell_id, references(:spells, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:character_spells, [:character_id])
    create index(:character_spells, [:spell_id])
    create unique_index(:character_spells, [:character_id, :spell_id])
  end
end
