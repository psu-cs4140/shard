defmodule ShardWeb.Admin.RoomController do
  use ShardWeb, :controller
  alias Shard.World
  alias Shard.World.Room

  def index(conn, _params) do
    rooms = World.list_rooms()
    render(conn, :index, rooms: rooms)
  end

  def new(conn, _params) do
    changeset = World.change_room(%Room{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"room" => room_params}) do
    case World.create_room(room_params) do
      {:ok, room} -> redirect(conn, to: ~p"/admin/rooms/#{room}")
      {:error, %Ecto.Changeset{} = changeset} -> render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    room = World.get_room!(id)
    render(conn, :show, room: room)
  end

  def edit(conn, %{"id" => id}) do
    room = World.get_room!(id)
    changeset = World.change_room(room)
    render(conn, :edit, room: room, changeset: changeset)
  end

  def update(conn, %{"id" => id, "room" => params}) do
    room = World.get_room!(id)

    case World.update_room(room, params) do
      {:ok, room} ->
        redirect(conn, to: ~p"/admin/rooms/#{room}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, room: room, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    room = World.get_room!(id)
    {:ok, _} = World.delete_room(room)
    redirect(conn, to: ~p"/admin/rooms")
  end
end
