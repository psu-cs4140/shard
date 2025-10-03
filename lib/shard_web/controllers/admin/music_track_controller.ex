defmodule ShardWeb.Admin.MusicTrackController do
  use ShardWeb, :controller

  alias Ecto.Changeset
  alias Shard.Media
  alias Shard.Media.MusicTrack

  # If you have this plug, keep it; otherwise remove this line or add the stub I shared.
  plug ShardWeb.AdminController, :require_admin

  @allowed_exts ~w(.mp3 .wav .ogg .m4a .aac)

  ## -------- Actions --------

  @impl true
  def index(conn, _params) do
    tracks =
      case function_exported?(Media, :list_music_tracks, 1) do
        true -> Media.list_music_tracks(only_active: false)
        false -> Media.list_music_tracks()
      end

    render(conn, :index, tracks: tracks)
  end

  @impl true
  def new(conn, _params) do
    changeset = Media.change_music_track(%MusicTrack{})
    render(conn, :new, changeset: changeset)
  end

  @impl true
  def create(conn, %{"music_track" => params}) do
    case persist_upload(Map.get(params, "audio")) do
      {:ok, url, orig} ->
        params = Map.merge(params, %{"url" => url, "original_filename" => orig})

        case Media.create_music_track(params) do
          {:ok, track} ->
            conn
            |> put_flash(:info, "Track created.")
            |> redirect(to: ~p"/admin/music/#{track}")

          {:error, %Changeset{} = changeset} ->
            render(conn, :new, changeset: changeset)
        end

      :no_file ->
        %MusicTrack{}
        |> Media.change_music_track(params)
        |> Changeset.add_error(:url, "audio file is required")
        |> then(&render(conn, :new, changeset: &1))

      {:error, msg} ->
        %MusicTrack{}
        |> Media.change_music_track(params)
        |> Changeset.add_error(:url, msg)
        |> then(&render(conn, :new, changeset: &1))
    end
  end

  @impl true
  def show(conn, %{"id" => id}) do
    track = Media.get_music_track!(id)
    render(conn, :show, track: track)
  end

  @impl true
  def edit(conn, %{"id" => id}) do
    track = Media.get_music_track!(id)
    render(conn, :edit, track: track, changeset: Media.change_music_track(track))
  end

  @impl true
  def update(conn, %{"id" => id, "music_track" => params}) do
    track = Media.get_music_track!(id)

    {file_result, params} =
      case Map.get(params, "audio") do
        %Plug.Upload{} = up ->
          case persist_upload(up) do
            {:ok, url, orig} ->
              {:ok, Map.merge(params, %{"url" => url, "original_filename" => orig})}

            {:error, _} = err ->
              {err, params}
          end

        _ ->
          {:ok, params}
      end

    with {:ok, params} <- file_result do
      case Media.update_music_track(track, params) do
        {:ok, track} ->
          conn
          |> put_flash(:info, "Track updated.")
          |> redirect(to: ~p"/admin/music/#{track}")

        {:error, %Changeset{} = changeset} ->
          render(conn, :edit, track: track, changeset: changeset)
      end
    else
      {:error, msg} ->
        track
        |> Media.change_music_track(params)
        |> Changeset.add_error(:url, msg)
        |> then(&render(conn, :edit, track: track, changeset: &1))
    end
  end

  @impl true
  def delete(conn, %{"id" => id}) do
    track = Media.get_music_track!(id)
    {:ok, _} = Media.delete_music_track(track)

    conn
    |> put_flash(:info, "Track deleted.")
    |> redirect(to: ~p"/admin/music")
  end

  ## -------- Helpers --------

  defp persist_upload(nil), do: :no_file

  defp persist_upload(%Plug.Upload{path: tmp, filename: name}) do
    ext = name |> Path.extname() |> String.downcase()

    if ext in @allowed_exts do
      dest_dir = Application.app_dir(:shard, "priv/uploads/music")
      File.mkdir_p!(dest_dir)

      # reasonably unique basename
      hash =
        :crypto.hash(:sha256, "#{name}:#{System.system_time()}:#{System.unique_integer()}")
        |> Base.url_encode64(padding: false)

      dest = Path.join(dest_dir, hash <> ext)

      case File.cp(tmp, dest) do
        :ok ->
          # Static is expected at /uploads via Plug.Static in Endpoint
          {:ok, "/uploads/music/" <> Path.basename(dest), name}

        {:error, reason} ->
          {:error, "failed to store upload: #{inspect(reason)}"}
      end
    else
      {:error, "unsupported file type (allowed: #{Enum.join(@allowed_exts, ", ")})"}
    end
  end
end
