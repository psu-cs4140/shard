defmodule Shard.Repo.Migrations.CreateQuests do
  use Ecto.Migration

  def change do
    create table(:quests) do
      add :title, :string, null: false
      add :description, :text, null: false
      add :short_description, :string
      add :quest_type, :string, default: "main" # main, side, daily, repeatable
      add :difficulty, :string, default: "normal" # easy, normal, hard, epic, legendary
      add :min_level, :integer, default: 1
      add :max_level, :integer
      add :experience_reward, :integer, default: 0
      add :gold_reward, :integer, default: 0
      add :item_rewards, :map, default: %{} # {item_id: quantity}
      add :prerequisites, :map, default: %{} # {quest_ids: [], level: int, items: []}
      add :objectives, :map, default: %{} # {type: "kill", target: "goblin", count: 5, current: 0}
      add :status, :string, default: "available" # available, in_progress, completed, failed, locked
      add :is_repeatable, :boolean, default: false
      add :cooldown_hours, :integer # for repeatable quests
      add :giver_npc_id, references(:npcs, on_delete: :nilify_all)
      add :turn_in_npc_id, references(:npcs, on_delete: :nilify_all)
      add :location_hint, :string
      add :time_limit, :integer # in hours, null means no time limit
      add :faction_requirement, :string
      add :faction_reward, :map, default: %{} # {faction_name: reputation_points}
      add :is_active, :boolean, default: true
      add :sort_order, :integer, default: 0
      add :properties, :map, default: %{} # for custom properties

      timestamps(type: :utc_datetime)
    end

    create index(:quests, [:quest_type])
    create index(:quests, [:difficulty])
    create index(:quests, [:status])
    create index(:quests, [:min_level])
    create index(:quests, [:giver_npc_id])
    create index(:quests, [:turn_in_npc_id])
    create index(:quests, [:is_active])
    create index(:quests, [:sort_order])
  end
end
