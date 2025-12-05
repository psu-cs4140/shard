defmodule Shard.Repo.Migrations.AddMiningFieldsToCharacters do
  use Ecto.Migration

  def change do
    alter table(:characters) do
      add :is_mining, :boolean, default: false, null: false
      add :mining_started_at, :utc_datetime_usec, null: true
    end
  end
end
