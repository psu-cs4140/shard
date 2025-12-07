defmodule Shard.Repo.Migrations.CreateDailyLoginRewards do
  use Ecto.Migration

  def change do
    create table(:daily_login_rewards) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :last_claim_date, :date, null: false
      add :streak_count, :integer, default: 1, null: false
      add :total_claims, :integer, default: 1, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:daily_login_rewards, [:user_id])
    create index(:daily_login_rewards, [:last_claim_date])
  end
end
