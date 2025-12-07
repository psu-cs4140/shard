defmodule Shard.Repo.Migrations.CreateTimeCycles do
  use Ecto.Migration

  def change do
    create table(:time_cycles) do
      add :current_minute, :integer, null: false, default: 0
      add :current_hour, :integer, null: false, default: 12
      add :current_day, :integer, null: false, default: 1
      add :time_multiplier, :float, null: false, default: 1.0

      timestamps(type: :utc_datetime)
    end

    # Ensure only one time cycle record exists
    create unique_index(:time_cycles, [:id])
  end
end
