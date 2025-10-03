defmodule ShardWeb.PlayLive do
  use ShardWeb, :live_view

  import Ecto.Query, only: [from: 2]
  alias Shard.Repo
  alias Shard.World.{Room, Exit}
  alias Shard.Music

  # Discover Exit field names once at compile time
  @exit_fields Exit.__schema__(:fields)

  @from_field (cond do
                 :from_id in @exit_fields -> :from_id
                 :from_room_id in @exit_fields -> :from_room_id
                 :source_id in @exit_fields -> :source_id
                 :src_id in @exit_fields -> :src_id
                 :from in @exit_fields -> :from
                 true -> raise "Exit schema missing origin FK. Fields: #{inspect(@exit_fields)}"
               end)

  @to_field (cond do
               :to_id in @exit_fields ->
                 :to_id

               :to_room_id in @exit_fields ->
                 :to_room_id

               :dest_id in @exit_fields ->
                 :dest_id

               :destination_id in @exit_fields ->
                 :destination_id

               :to in @exit_fields ->
                 :to

               true ->
                 raise "Exit schema missing destination FK. Fields: #{inspect(@exit_fields)}"
             end)

  @dir_field (cond do
                :dir in @exit_fields ->
                  :dir

                :direction in @exit_fields ->
                  :direction

                true ->
                  raise "Exit schema missing :dir/:direction. Fields: #{inspect(@exit_fields)}"
              end)

  @impl true
  def mount(_params, _session, socket) do
    room =
      Repo.get_by(Room, slug: "start") ||
        Repo.one(from r in Room, limit: 1)

    flash =
      if is_nil(room),
        do: "No rooms found. Create one at Admin → Rooms.",
        else: nil

    socket =
      socket
      |> assign(room: room, exits: exits_for(room), flash_info: flash)
      |> maybe_push_room_music()

    {:ok, socket}
  end

  @impl true
  def handle_event("go", %{"dir" => dir}, socket), do: move_and_assign(dir, socket)

  @impl true
  def handle_event("key", %{"key" => key}, socket) do
    dir =
      case key do
        "w" -> "n"
        "ArrowUp" -> "n"
        "s" -> "s"
        "ArrowDown" -> "s"
        "a" -> "w"
        "ArrowLeft" -> "w"
        "d" -> "e"
        "ArrowRight" -> "e"
        _ -> nil
      end

    if is_nil(dir), do: {:noreply, socket}, else: move_and_assign(dir, socket)
  end

  # ——— Helpers ———

  defp move_and_assign(dir, socket) do
    case socket.assigns.room do
      nil ->
        {:noreply,
         assign(socket, :flash_info, "No room loaded yet. Create one in Admin → Rooms.")}

      curr ->
        case Shard.Game.move(curr.id, dir) do
          {:ok, room} ->
            socket =
              socket
              |> assign(room: room, exits: exits_for(room), flash_info: nil)
              |> maybe_push_room_music()

            {:noreply, socket}

          {:error, :no_exit} ->
            {:noreply, assign(socket, :flash_info, "No exit #{dir}.")}
        end
    end
  end

  defp exits_for(nil), do: []

  defp exits_for(%Room{id: id}) do
    exits = Repo.all(from e in Exit, where: field(e, ^@from_field) == ^id)
    for e <- exits, do: %{dir: Map.get(e, @dir_field), to_id: Map.get(e, @to_field)}
  end

  # Pushes the appropriate music event if the LiveView is connected.
  defp maybe_push_room_music(socket) do
    if connected?(socket), do: push_room_music(socket), else: socket
  end

  defp push_room_music(socket) do
    user = current_user_from(socket)
    room = socket.assigns[:room]

    user_music? = user && Map.get(user, :music_enabled) == true
    music_key = room && Map.get(room, :music_key)

    cond do
      not user_music? ->
        push_event(socket, "stop-room-music", %{})

      is_nil(music_key) or music_key == "" ->
        push_event(socket, "stop-room-music", %{})

      true ->
        case Music.url(music_key) do
          nil ->
            push_event(socket, "stop-room-music", %{})

          src ->
            # Add static fingerprint/version if enabled
            src = ShardWeb.Endpoint.static_path(src)
            volume = clamp(Map.get(room, :music_volume, 70), 0, 100)
            loop = Map.get(room, :music_loop, true) == true

            push_event(socket, "play-room-music", %{
              src: src,
              # expected 0..100 by your RoomMusic hook
              volume: volume,
              loop: loop
            })
        end
    end
  end

  # Tries common assigns to find the current user.
  defp current_user_from(socket) do
    cond do
      is_map(socket.assigns[:current_scope]) and is_map(socket.assigns.current_scope[:user]) ->
        socket.assigns.current_scope.user

      not is_nil(socket.assigns[:current_user]) ->
        socket.assigns.current_user

      true ->
        nil
    end
  end

  defp clamp(v, min, max) when is_integer(v), do: v |> max(min) |> min(max)
  defp clamp(v, min, max) when is_float(v), do: v |> trunc() |> clamp(min, max)
  defp clamp(_v, min, _max), do: min
end
