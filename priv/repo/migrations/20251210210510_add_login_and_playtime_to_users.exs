defmodule Shard.Repo.Migrations.AddLoginAndPlaytimeToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :login_count, :integer, default: 0, null: false
      add :total_playtime_seconds, :integer, default: 0, null: false
      add :last_login_at, :utc_datetime_usec
    end
  end
end
