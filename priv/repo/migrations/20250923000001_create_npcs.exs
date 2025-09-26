defmodule Shard.Repo.Migrations.CreateNpcs do
  use Ecto.Migration

  def change do
    create table(:npcs) do
      add :name, :string, null: false
      add :description, :text
      add :level, :integer, default: 1
      add :health, :integer, default: 100
      add :max_health, :integer, default: 100
      add :mana, :integer, default: 50
      add :max_mana, :integer, default: 50
      add :strength, :integer, default: 10
      add :dexterity, :integer, default: 10
      add :intelligence, :integer, default: 10
      add :constitution, :integer, default: 10
      add :experience_reward, :integer, default: 0
      add :gold_reward, :integer, default: 0
      add :npc_type, :string, default: "neutral" # neutral, friendly, hostile, merchant, quest_giver
      add :dialogue, :text
      add :inventory, :map, default: %{}
      add :location_x, :integer
      add :location_y, :integer
      add :location_z, :integer, default: 0
      add :room_id, references(:rooms, on_delete: :nilify_all)
      add :is_active, :boolean, default: true
      add :respawn_time, :integer # in seconds, null means no respawn
      add :last_death_at, :utc_datetime
      add :faction, :string
      add :aggression_level, :integer, default: 0 # 0 = peaceful, 10 = very aggressive
      add :movement_pattern, :string, default: "stationary" # stationary, patrol, random, follow
      add :properties, :map, default: %{} # for custom properties

      timestamps(type: :utc_datetime)
    end

    create index(:npcs, [:room_id])
    create index(:npcs, [:npc_type])
    create index(:npcs, [:is_active])
    create index(:npcs, [:location_x, :location_y, :location_z])
    create index(:npcs, [:faction])
  end
end
