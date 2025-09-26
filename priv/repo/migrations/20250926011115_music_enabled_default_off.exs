# mix ecto.gen.migration music_enabled_default_off
defmodule Shard.Repo.Migrations.MusicEnabledDefaultOff do
  use Ecto.Migration

  def up do
    execute "UPDATE users SET music_enabled = false WHERE music_enabled IS NULL"

    alter table(:users) do
      modify :music_enabled, :boolean, null: false, default: false
    end
  end

  def down do
    alter table(:users) do
      modify :music_enabled, :boolean, null: true, default: true
    end
  end
end
