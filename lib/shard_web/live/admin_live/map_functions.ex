defmodule ShardWeb.AdminLive.MapFunctions do
  @moduledoc """
  Business logic functions for Map LiveView operations.
  These functions handle the create/update operations for rooms and doors.
  """

  alias Shard.Map
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [put_flash: 3]

  def save_room(socket, room_params) do
    case socket.assigns.editing do
      :room
      when not is_nil(socket.assigns.changeset) and
             not is_nil(socket.assigns.changeset.data.id) ->
        case Map.update_room(socket.assigns.changeset.data, room_params) do
          {:ok, _room} ->
            rooms = reload_rooms(socket)

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
            rooms = reload_rooms(socket)

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
    # Convert string parameters to proper types
    converted_params = convert_door_params(door_params)

    case socket.assigns.editing do
      :door
      when not is_nil(socket.assigns.changeset) and
             not is_nil(socket.assigns.changeset.data.id) ->
        case Map.update_door(socket.assigns.changeset.data, converted_params) do
          {:ok, _door} ->
            doors = reload_doors(socket)

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
        case Map.create_door(converted_params) do
          {:ok, _door} ->
            doors = reload_doors(socket)

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

  defp convert_door_params(params) do
    %{}
    |> put_param(params, "from_room_id", &to_integer/1)
    |> put_param(params, "to_room_id", &to_integer/1)
    |> put_param(params, "direction")
    |> put_param(params, "door_type")
    |> put_param(params, "is_locked", &to_boolean/1)
    |> put_param(params, "key_required")
    |> put_param(params, "name")
    |> put_param(params, "description")
    |> put_param(params, "new_dungeon", &to_boolean/1)
    |> put_param(params, "id", &to_integer/1)
  end

  defp put_param(acc, params, key, converter \\ fn x -> x end) do
    case :maps.get(key, params, nil) do
      nil -> acc
      value -> :maps.put(String.to_atom(key), converter.(value), acc)
    end
  end

  defp to_integer(value) when is_integer(value), do: value

  defp to_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> value
    end
  end

  defp to_boolean("true"), do: true
  defp to_boolean("false"), do: false
  defp to_boolean(true), do: true
  defp to_boolean(false), do: false
  defp to_boolean(value), do: value

  # Helper functions to reload rooms/doors with zone filtering
  defp reload_rooms(socket) do
    if socket.assigns.selected_zone_id do
      Map.list_rooms_by_zone(socket.assigns.selected_zone_id)
    else
      Map.list_rooms()
    end
  end

  defp reload_doors(socket) do
    if socket.assigns.selected_zone_id do
      rooms = Map.list_rooms_by_zone(socket.assigns.selected_zone_id)
      room_ids = Enum.map(rooms, & &1.id)

      # Get only doors that connect rooms within this zone
      all_doors = Map.list_doors()

      Enum.filter(all_doors, fn door ->
        door.from_room_id in room_ids && door.to_room_id in room_ids
      end)
    else
      Map.list_doors()
    end
  end
end
