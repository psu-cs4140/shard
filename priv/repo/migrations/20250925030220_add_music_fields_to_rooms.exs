defmodule Shard.Repo.Migrations.AddMusicFieldsToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :music_key, :string
      add :music_volume, :integer, null: false, default: 70
      add :music_loop, :boolean, null: false, default: true
    end

    create index(:rooms, [:music_key])
  end
end
