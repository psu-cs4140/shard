defmodule ShardWeb.PlayLive do
  use ShardWeb, :live_view
  import Ecto.Query, only: [from: 2]
  alias Shard.Repo
  alias Shard.World.{Room, Exit}

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

    {:ok, assign(socket, room: room, exits: exits_for(room), flash_info: nil)}
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

  defp move_and_assign(dir, socket) do
    curr = socket.assigns.room

    case Shard.Game.move(curr.id, dir) do
      {:ok, room} ->
        {:noreply, assign(socket, room: room, exits: exits_for(room), flash_info: nil)}

      {:error, :no_exit} ->
        {:noreply, assign(socket, :flash_info, "No exit #{dir}.")}
    end
  end

  defp exits_for(nil), do: []

  defp exits_for(%Room{id: id}) do
    # Use dynamic field names; then normalize to %{dir: ..., to_id: ...}
    exits = Repo.all(from e in Exit, where: field(e, ^@from_field) == ^id)

    for e <- exits do
      %{dir: Map.get(e, @dir_field), to_id: Map.get(e, @to_field)}
    end
  end
end
