defmodule ShardWeb.AdminLive.MapFunctions do
  @moduledoc """
  Business logic functions for Map LiveView operations.
  These functions handle the create/update operations for rooms and doors.
  """

  alias Shard.Map
  import Phoenix.Component, only: [assign: 2, assign: 3]
  import Phoenix.LiveView, only: [put_flash: 3]

  def save_room(socket, room_params) do
    case socket.assigns.editing do
      :room
      when not is_nil(socket.assigns.changeset) and
             not is_nil(socket.assigns.changeset.data.id) ->
        case Map.update_room(socket.assigns.changeset.data, room_params) do
          {:ok, _room} ->
            rooms = Map.list_rooms()

            {:ok,
             socket
             |> assign(:rooms, rooms)
             |> assign(:editing, nil)
             |> assign(:changeset, nil)
             |> put_flash(:info, "Room updated successfully")}

          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end

      _ ->
        case Map.create_room(room_params) do
          {:ok, _room} ->
            rooms = Map.list_rooms()

            {:ok,
             socket
             |> assign(:rooms, rooms)
             |> assign(:editing, nil)
             |> assign(:changeset, nil)
             |> put_flash(:info, "Room created successfully")}

          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end
    end
  end

  def save_door(socket, door_params) do
    case socket.assigns.editing do
      :door
      when not is_nil(socket.assigns.changeset) and
             not is_nil(socket.assigns.changeset.data.id) ->
        case Map.update_door(socket.assigns.changeset.data, door_params) do
          {:ok, _door} ->
            doors = Map.list_doors()

            {:ok,
             socket
             |> assign(:doors, doors)
             |> assign(:editing, nil)
             |> assign(:changeset, nil)
             |> put_flash(:info, "Door updated successfully")}

          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end

      _ ->
        case Map.create_door(door_params) do
          {:ok, _door} ->
            doors = Map.list_doors()

            {:ok,
             socket
             |> assign(:doors, doors)
             |> assign(:editing, nil)
             |> assign(:changeset, nil)
             |> put_flash(:info, "Door created successfully")}

          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end
    end
  end
end
