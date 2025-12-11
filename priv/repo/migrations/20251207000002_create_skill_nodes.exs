defmodule Shard.Repo.Migrations.CreateSkillNodes do
  use Ecto.Migration

  def change do
    create table(:skill_nodes) do
      add :name, :string, null: false
      add :description, :text
      add :xp_cost, :integer, null: false
      add :prerequisites, {:array, :integer}, default: []
      add :effects, :map, default: %{}
      add :position_x, :integer, default: 0
      add :position_y, :integer, default: 0
      add :is_active, :boolean, default: true, null: false
      add :skill_tree_id, references(:skill_trees, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:skill_nodes, [:skill_tree_id])
  end
end
