defmodule Shard.Repo.Migrations.AddMusicEnabledToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :music_enabled, :boolean, null: false, default: false
    end
  end
end
