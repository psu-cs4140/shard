defmodule Shard.Repo.Migrations.CreateCharacterSkills do
  use Ecto.Migration

  def change do
    create table(:character_skills) do
      add :unlocked_at, :utc_datetime
      add :character_id, references(:characters, on_delete: :delete_all), null: false
      add :skill_node_id, references(:skill_nodes, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:character_skills, [:character_id, :skill_node_id])
    create index(:character_skills, [:character_id])
    create index(:character_skills, [:skill_node_id])
  end
end
