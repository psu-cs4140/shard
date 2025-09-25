defmodule Shard.Repo.Migrations.CreateQuestAcceptances do
  use Ecto.Migration

  def change do
    create table(:quest_acceptances) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :quest_id, references(:quests, on_delete: :delete_all), null: false
      add :status, :string, default: "accepted", null: false
      add :accepted_at, :utc_datetime, null: false
      add :completed_at, :utc_datetime
      add :progress, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:quest_acceptances, [:user_id, :quest_id])
    create index(:quest_acceptances, [:user_id])
    create index(:quest_acceptances, [:quest_id])
    create index(:quest_acceptances, [:status])
  end
end
