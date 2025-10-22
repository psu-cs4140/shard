defmodule ShardWeb.AdminLive.MapHandlers do
  @moduledoc """
  Event handlers for the Map LiveView.
  Use defdelegate in the main LiveView to delegate handle_event calls here.
  """

  alias Shard.Map
  alias Shard.Map.{Room, Door}
  alias Shard.Repo
  alias Shard.AI
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [put_flash: 3]
  import ShardWeb.AdminLive.MapFunctions
  import Ecto.Query

  def handle_change_tab(%{"tab" => tab}, socket) do
    {:noreply, assign(socket, :tab, tab)}
  end

  # Room events
  def handle_new_room(_params, socket) do
    changeset = Map.change_room(%Room{})
    {:noreply, socket |> assign(:changeset, changeset) |> assign(:editing, :room)}
  end

  def handle_edit_room(%{"id" => id}, socket) do
    room = Map.get_room!(id)
    changeset = Map.change_room(room)
    {:noreply, socket |> assign(:changeset, changeset) |> assign(:editing, :room)}
  end

  def handle_view_room(%{"id" => id}, socket) do
    room = Map.get_room!(id)
    doors_from = get_doors_from_room(room.id) |> Repo.all() |> Repo.preload(:to_room)
    doors_to = get_doors_to_room(room.id) |> Repo.all() |> Repo.preload(:from_room)

    {:noreply,
     socket
     |> assign(:viewing, room)
     |> assign(:doors_from, doors_from)
     |> assign(:doors_to, doors_to)
     |> assign(:changeset, Map.change_room(room))
     |> assign(:tab, "room_details")}
  end

  def handle_delete_room(%{"id" => id}, socket) do
    room = Map.get_room!(id)
    {:ok, _} = Map.delete_room(room)

    rooms = Map.list_rooms()
    doors = Map.list_doors()

    {:noreply,
     socket
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> put_flash(:info, "Room deleted successfully")}
  end

  def handle_validate_room(%{"room" => room_params}, socket) do
    changeset =
      if socket.assigns.editing == :room && socket.assigns.changeset.data.id do
        Map.change_room(socket.assigns.changeset.data, room_params)
      else
        Map.change_room(%Room{}, room_params)
      end
      |> Map.put_action(:validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_save_room(%{"room" => room_params}, socket) do
    case save_room(socket, room_params) do
      {:ok, socket} -> {:noreply, socket}
      {:error, socket} -> {:noreply, socket}
    end
  end

  def handle_apply_and_save(%{"room" => room_params}, socket) do
    case Map.update_room(socket.assigns.viewing, room_params) do
      {:ok, updated_room} ->
        rooms = Map.list_rooms()

        {:noreply,
         socket
         |> assign(:rooms, rooms)
         |> assign(:viewing, updated_room)
         |> assign(:changeset, Map.change_room(updated_room))
         |> put_flash(:info, "Room updated successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_generate_description(_params, socket) do
    zone_description = "A dark and mysterious forest."

    adjacent_rooms = get_adjacent_rooms_for_ai(socket.assigns.viewing)

    case AI.generate_room_description(zone_description, adjacent_rooms) do
      {:ok, description} ->
        changeset =
          Ecto.Changeset.put_change(socket.assigns.changeset, :description, description)

        {:noreply, assign(socket, :changeset, changeset)}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to generate description: #{reason}")}
    end
  end

  def handle_cancel_room(_params, socket) do
    {:noreply, socket |> assign(:editing, nil) |> assign(:changeset, nil)}
  end

  def handle_back_to_rooms(_params, socket) do
    {:noreply, assign(socket, :tab, "rooms")}
  end

  # Door events
  def handle_new_door(_params, socket) do
    changeset = Map.change_door(%Door{})
    {:noreply, socket |> assign(:changeset, changeset) |> assign(:editing, :door)}
  end

  def handle_edit_door(%{"id" => id}, socket) do
    door = Map.get_door!(id)
    changeset = Map.change_door(door)
    {:noreply, socket |> assign(:changeset, changeset) |> assign(:editing, :door)}
  end

  def handle_delete_door(%{"id" => id}, socket) do
    door = Map.get_door!(id)
    {:ok, _} = Map.delete_door(door)

    rooms = Map.list_rooms()
    doors = Map.list_doors()

    {:noreply,
     socket
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> put_flash(:info, "Door deleted successfully")}
  end

  def handle_validate_door(%{"door" => door_params}, socket) do
    changeset =
      if socket.assigns.editing == :door && socket.assigns.changeset.data.id do
        Map.change_door(socket.assigns.changeset.data, door_params)
      else
        Map.change_door(%Door{}, door_params)
      end
      |> Map.put_action(:validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_save_door(%{"door" => door_params}, socket) do
    case save_door(socket, door_params) do
      {:ok, socket} -> {:noreply, socket}
      {:error, socket} -> {:noreply, socket}
    end
  end

  def handle_cancel_door(_params, socket) do
    {:noreply, socket |> assign(:editing, nil) |> assign(:changeset, nil)}
  end

  # Map interaction events
  def handle_zoom_in(_params, socket) do
    {:noreply, assign(socket, :zoom, min(socket.assigns.zoom * 1.2, 5.0))}
  end

  def handle_zoom_out(_params, socket) do
    {:noreply, assign(socket, :zoom, max(socket.assigns.zoom / 1.2, 0.2))}
  end

  def handle_reset_view(_params, socket) do
    {:noreply,
     socket
     |> assign(:zoom, 1.0)
     |> assign(:pan_x, 0)
     |> assign(:pan_y, 0)}
  end

  def handle_mousedown(%{"clientX" => x, "clientY" => y}, socket) do
    {:noreply, assign(socket, :drag_start, %{x: x, y: y})}
  end

  def handle_mousemove(%{"clientX" => x, "clientY" => y}, socket) do
    case socket.assigns.drag_start do
      nil ->
        {:noreply, socket}

      start ->
        delta_x = x - start.x
        delta_y = y - start.y

        {:noreply,
         socket
         |> assign(:pan_x, socket.assigns.pan_x + delta_x)
         |> assign(:pan_y, socket.assigns.pan_y + delta_y)
         |> assign(:drag_start, %{x: x, y: y})}
    end
  end

  def handle_mouseup(_params, socket) do
    {:noreply, assign(socket, :drag_start, nil)}
  end

  def handle_mouseleave(_params, socket) do
    {:noreply, assign(socket, :drag_start, nil)}
  end

  # Helper functions
  defp get_doors_from_room(room_id) do
    from d in Door,
      where: d.from_room_id == ^room_id
  end

  defp get_doors_to_room(room_id) do
    from d in Door,
      where: d.to_room_id == ^room_id
  end

  defp get_adjacent_rooms_for_ai(nil), do: []

  defp get_adjacent_rooms_for_ai(room) do
    # Get rooms connected by doors from this room
    doors_from = get_doors_from_room(room.id) |> Repo.all() |> Repo.preload(:to_room)
    doors_to = get_doors_to_room(room.id) |> Repo.all() |> Repo.preload(:from_room)

    adjacent_rooms = Enum.map(doors_from, & &1.to_room) ++ Enum.map(doors_to, & &1.from_room)
    Enum.uniq_by(adjacent_rooms, & &1.id)
  end

  # Generate default map
  def handle_generate_default_map(_params, socket) do
    Shard.Repo.delete_all(Door)
    Shard.Repo.delete_all(Room)

    rooms = create_default_rooms()
    create_default_doors(rooms)

    rooms = Map.list_rooms()
    doors = Map.list_doors()

    {:noreply,
     socket
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> put_flash(:info, "Default 3x3 map generated successfully!")}
  end

  defp create_default_rooms do
    for x <- 0..2, y <- 0..2 do
      create_room_at_coordinates(x, y)
    end
  end

  defp create_room_at_coordinates(x, y) do
    name = "Room #{x},#{y}"
    description = "A room in the default map at coordinates (#{x}, #{y})"
    room_type = if x == 1 and y == 1, do: "safe_zone", else: "standard"

    {:ok, room} =
      Map.create_room(%{
        name: name,
        description: description,
        x_coordinate: x,
        y_coordinate: y,
        z_coordinate: 0,
        room_type: room_type,
        is_public: true
      })

    room
  end

  defp create_default_doors(rooms) do
    for x <- 0..2, y <- 0..2 do
      current_room = find_room_at_coordinates(rooms, x, y)
      create_doors_from_room(rooms, current_room, x, y)
    end
  end

  defp find_room_at_coordinates(rooms, x, y) do
    Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
  end

  defp create_doors_from_room(rooms, current_room, x, y) do
    create_east_door(rooms, current_room, x, y)
    create_south_door(rooms, current_room, x, y)
  end

  defp create_east_door(rooms, current_room, x, y) when x < 2 do
    east_room = find_room_at_coordinates(rooms, x + 1, y)
    create_door_between_rooms(current_room, east_room, "east")
  end

  defp create_east_door(_rooms, _current_room, _x, _y), do: :ok

  defp create_south_door(rooms, current_room, x, y) when y < 2 do
    south_room = find_room_at_coordinates(rooms, x, y + 1)
    create_door_between_rooms(current_room, south_room, "south")
  end

  defp create_south_door(_rooms, _current_room, _x, _y), do: :ok

  defp create_door_between_rooms(from_room, to_room, direction) do
    {:ok, _door} =
      Map.create_door(%{
        from_room_id: from_room.id,
        to_room_id: to_room.id,
        direction: direction,
        door_type: "standard",
        is_locked: false
      })
  end

  # Delete all map data
  def handle_delete_all_map_data(_params, socket) do
    Shard.Repo.delete_all(Door)
    Shard.Repo.delete_all(Room)

    rooms = Map.list_rooms()
    doors = Map.list_doors()

    {:noreply,
     socket
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> put_flash(:info, "All map data deleted successfully!")}
  end
end
