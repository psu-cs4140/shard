# lib/shard/media.ex
defmodule Shard.Media do
  @moduledoc """
  Media context for music tracks.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo
  alias Shard.Media.MusicTrack

  # Supports opts like: list_music_tracks(only_active: false)
  def list_music_tracks(opts \\ []) do
    base = from(t in MusicTrack)

    query =
      case Keyword.get(opts, :only_active, true) do
        true -> from t in base, where: t.public == true
        false -> base
      end

    Repo.all(query)
  end

  def get_music_track!(id), do: Repo.get!(MusicTrack, id)

  def create_music_track(attrs \\ %{}) do
    %MusicTrack{}
    |> MusicTrack.changeset(attrs)
    |> Repo.insert()
  end

  def update_music_track(%MusicTrack{} = t, attrs) do
    t
    |> MusicTrack.changeset(attrs)
    |> Repo.update()
  end

  def delete_music_track(%MusicTrack{} = t), do: Repo.delete(t)

  def change_music_track(%MusicTrack{} = t, attrs \\ %{}) do
    MusicTrack.changeset(t, attrs)
  end
end
