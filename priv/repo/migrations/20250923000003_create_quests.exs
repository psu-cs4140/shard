defmodule Shard.Repo.Migrations.CreateQuests do
  use Ecto.Migration

  def change do
    create table(:quests) do
      add :title, :string, null: false
      add :description, :text, null: false
      add :short_description, :string
      # main, side, daily, repeatable
      add :quest_type, :string, default: "main"
      # easy, normal, hard, epic, legendary
      add :difficulty, :string, default: "normal"
      add :min_level, :integer, default: 1
      add :max_level, :integer
      add :experience_reward, :integer, default: 0
      add :gold_reward, :integer, default: 0
      # {item_id: quantity}
      add :item_rewards, :map, default: %{}
      # {quest_ids: [], level: int, items: []}
      add :prerequisites, :map, default: %{}
      # {type: "kill", target: "goblin", count: 5, current: 0}
      add :objectives, :map, default: %{}
      # available, in_progress, completed, failed, locked
      add :status, :string, default: "available"
      add :is_repeatable, :boolean, default: false
      # for repeatable quests
      add :cooldown_hours, :integer
      add :giver_npc_id, references(:npcs, on_delete: :nilify_all)
      add :turn_in_npc_id, references(:npcs, on_delete: :nilify_all)
      add :location_hint, :string
      # in hours, null means no time limit
      add :time_limit, :integer
      add :faction_requirement, :string
      # {faction_name: reputation_points}
      add :faction_reward, :map, default: %{}
      add :is_active, :boolean, default: true
      add :sort_order, :integer, default: 0
      # for custom properties
      add :properties, :map, default: %{}

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
