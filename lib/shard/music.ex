defmodule Shard.Music do
  @moduledoc """
  Resolve room music by key without a manifest.

  Accepts:
    * catalog keys like "sneaky_snitch" or "organ_filler" (see @catalog)
    * direct filenames under /audio, e.g. "kevin_macleod_sneaky_snitch.mp3"
      or "freepd/organ_filler.mp3"

  Returns maps including both `:url` (e.g., "/audio/…") and `:file`
  (relative to `audio/`) for compatibility.
  """

  # Built-ins (files must exist under priv/static/audio/)
  @catalog %{
    "sneaky_snitch" => %{
      file: "kevin_macleod_sneaky_snitch.mp3",
      title: "Sneaky Snitch",
      artist: "Kevin MacLeod",
      license: "CC BY 3.0",
      source: "incompetech.com"
    },
    "organ_filler" => %{
      file: "freepd/organ_filler.mp3",
      title: "Organ Filler",
      artist: "Kevin MacLeod",
      license: "Public Domain",
      source: "freepd.com"
    }
  }

  @type track :: %{
          key: String.t(),
          url: String.t(),
          file: String.t(),
          title: String.t() | nil,
          artist: String.t() | nil,
          license: String.t() | nil,
          source: String.t() | nil
        }

  # ---------- Public API -----------------------------------------------------

  @spec url(String.t() | nil) :: String.t() | nil
  def url(key) do
    case get(key) do
      %{url: url} -> url
      _ -> nil
    end
  end

  @spec exists?(String.t() | nil) :: boolean()
  def exists?(key), do: !!url(key)

  @spec get(String.t() | nil) :: track() | nil
  def get(nil), do: nil
  def get(""), do: nil

  def get(key) when is_binary(key) do
    cond do
      looks_like_filename?(key) ->
        file_track_if_present(key)

      true ->
        catalog_track(key) || db_track_if_present(key)
    end
  end

  # ---------- Internal -------------------------------------------------------

  # Treat keys with "/" or ".mp3" as direct filenames under /audio
  defp looks_like_filename?(key),
    do: String.contains?(key, "/") or String.ends_with?(key, ".mp3")

  defp file_track_if_present(file_or_rel) do
    rel = file_or_rel |> String.trim() |> String.trim_leading("/")
    rel = Path.join("audio", rel)
    if static_exists?(rel), do: track_from_rel(rel, normalize_key(file_or_rel)), else: nil
  end

  defp catalog_track(key) do
    case Map.get(@catalog, key) do
      %{file: file} = meta ->
        rel = Path.join("audio", String.trim_leading(file, "/"))
        if static_exists?(rel), do: track_from_rel(rel, key, meta), else: nil

      %{url: "/audio/" <> _ = url} = meta ->
        rel = String.trim_leading(url, "/")
        if static_exists?(rel), do: track_from_rel(rel, key, meta), else: nil

      _ ->
        nil
    end
  end

  # Optional DB fallback (guarded so it compiles even if the schema doesn't exist)
  defp db_track_if_present(key) do
    if Code.ensure_loaded?(Shard.Media.MusicTrack) and
         function_exported?(Shard.Media.MusicTrack, :__schema__, 1) do
      track_from_db(key)
    else
      nil
    end
  end

  defp track_from_db(key) do
    alias Shard.Repo
    alias Shard.Media.MusicTrack

    case Repo.get_by(MusicTrack, key: key, public: true) do
      nil ->
        nil

      %MusicTrack{file: file} = t ->
        rel = Path.join("audio", String.trim_leading(file || "", "/"))

        if static_exists?(rel) do
          track_from_rel(rel, key, %{
            title: t.title,
            artist: t.artist,
            license: t.license,
            source: t.source
          })
        else
          nil
        end
    end
  end

  defp track_from_rel(rel, key, meta \\ %{}) do
    %{
      key: key,
      url: "/" <> rel,
      file: String.replace_prefix(rel, "audio/", ""),
      title: Map.get(meta, :title),
      artist: Map.get(meta, :artist),
      license: Map.get(meta, :license),
      source: Map.get(meta, :source)
    }
  end

  defp static_exists?(rel), do: File.exists?(Path.join(static_root(), rel))
  defp static_root, do: Application.app_dir(:shard, "priv/static")
  defp normalize_key(key), do: key |> String.trim() |> String.trim_leading("/")
end
