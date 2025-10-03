defmodule Shard.Repo.Migrations.CreateMusicTracks do
  use Ecto.Migration

  def change do
    create table(:music_tracks) do
      add :key, :string, null: false
      add :title, :string, null: false
      add :artist, :string
      add :license, :string
      add :source, :string
      add :file, :string, null: false
      add :duration_seconds, :integer
      add :public, :boolean, null: false, default: true
      timestamps(type: :utc_datetime)
    end

    create unique_index(:music_tracks, [:key])
    create unique_index(:music_tracks, [:file])
  end
end
