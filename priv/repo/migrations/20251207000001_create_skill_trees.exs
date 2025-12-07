defmodule Shard.Repo.Migrations.CreateSkillTrees do
  use Ecto.Migration

  def change do
    create table(:skill_trees) do
      add :name, :string, null: false
      add :description, :text
      add :is_active, :boolean, default: true, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:skill_trees, [:name])
  end
end
