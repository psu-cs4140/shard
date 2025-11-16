defmodule Shard.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  def change do
    create table(:achievements) do
      add :name, :string, null: false
      add :description, :text, null: false
      add :icon, :string
      add :category, :string, null: false
      add :points, :integer, default: 0, null: false
      add :hidden, :boolean, default: false, null: false
      add :requirements, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:achievements, [:name])
    create index(:achievements, [:category])
    create index(:achievements, [:hidden])

    create table(:user_achievements) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :achievement_id, references(:achievements, on_delete: :delete_all), null: false
      add :earned_at, :utc_datetime
      add :progress, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_achievements, [:user_id, :achievement_id])
    create index(:user_achievements, [:user_id])
    create index(:user_achievements, [:achievement_id])
    create index(:user_achievements, [:earned_at])
  end
end
