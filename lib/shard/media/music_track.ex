# lib/shard/media/music_track.ex
defmodule Shard.Media.MusicTrack do
  use Ecto.Schema
  import Ecto.Changeset

  alias ShardWeb.Endpoint

  @timestamps_opts [type: :utc_datetime]

  schema "music_tracks" do
    field :key, :string
    field :title, :string
    field :artist, :string
    field :license, :string
    field :source, :string
    field :file, :string
    field :duration_seconds, :integer
    field :public, :boolean, default: true
    timestamps()
  end

  @doc "Changeset for creating/updating a music track."
  def changeset(track, attrs) do
    track
    |> cast(attrs, [:key, :title, :artist, :license, :source, :file, :duration_seconds, :public])
    |> validate_required([:file])
    |> update_change(:file, &String.trim/1)
    |> validate_file_path()
    |> validate_length(:title, max: 200)
    |> validate_length(:artist, max: 200)
    |> validate_length(:license, max: 100)
    |> validate_length(:source, max: 255)
    # If you created a partial unique index on key (WHERE key IS NOT NULL) its
    # default name is "music_tracks_key_index"; reference it explicitly:
    |> unique_constraint(:key, name: :music_tracks_key_index)
  end

  # Basic path safety: allow subfolders (e.g., "freepd/organ_filler.mp3"),
  # disallow traversal and empty values. We don't check for file existence here.
  defp validate_file_path(changeset) do
    validate_change(changeset, :file, fn :file, file ->
      f = file |> to_string() |> String.trim()

      cond do
        f == "" ->
          [file: "can't be blank"]

        String.contains?(f, ["..", "\\"]) ->
          [file: "invalid path"]

        true ->
          []
      end
    end)
  end

  @doc """
  Build the public URL (fingerprinted in prod) for this track.

  Examples:
    "/audio/kevin_macleod_sneaky_snitch.mp3"
    "/audio/freepd/organ_filler.mp3"
  """
  def url(%__MODULE__{file: file}) when is_binary(file) do
    ("/audio/" <> String.trim_leading(file, "/"))
    |> Endpoint.static_path()
  end

  @doc """
  Convert a MusicTrack struct into the map shape expected by Shard.Music.
  Includes both `:url` and `:file` (relative path).
  """
  def to_track(%__MODULE__{} = t) do
    rel = String.trim_leading(t.file || "", "/")

    %{
      key: t.key,
      url: url(t),
      file: rel,
      title: t.title,
      artist: t.artist,
      license: t.license,
      source: t.source,
      duration_seconds: t.duration_seconds
    }
  end

  @doc "Convenience query for public tracks."
  def public_query do
    import Ecto.Query, only: [from: 2]
    from m in __MODULE__, where: m.public == true
  end
end
