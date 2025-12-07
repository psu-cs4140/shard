defmodule Shard.Repo.Migrations.CreateWeatherTable do
  use Ecto.Migration

  def change do
    create table(:weather, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :zone_id, :binary_id, null: false
      add :weather_type, :string, null: false
      add :intensity, :integer, default: 1, null: false
      add :duration_minutes, :integer, default: 30, null: false
      add :started_at, :utc_datetime, null: false
      add :effects, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:weather, [:zone_id])
    create index(:weather, [:weather_type])
    create index(:weather, [:started_at])
    create index(:weather, [:zone_id, :started_at])
  end
end
