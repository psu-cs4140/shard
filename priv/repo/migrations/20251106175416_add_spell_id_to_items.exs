defmodule Shard.Repo.Migrations.AddSpellIdToItems do
  use Ecto.Migration

  def change do
    alter table(:items) do
      add :spell_id, references(:spells, on_delete: :nilify_all)
    end

    create index(:items, [:spell_id])
  end
end
