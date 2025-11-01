defmodule Shard.Map do
  @moduledoc """
  The Map context for managing rooms and doors in the MUD game.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Map.{Room, Door, Zone}

  # Zone functions

  @doc """
  Returns the list of zones.
  """
  def list_zones do
    Repo.all(Zone)
  end

  @doc """
  Returns all active zones ordered by display_order.
  """
  def list_active_zones do
    Repo.all(from z in Zone, where: z.is_active == true, order_by: [asc: z.display_order])
  end

  @doc """
  Gets a single zone by ID.
  """
  def get_zone!(id) do
    Repo.get!(Zone, id)
  end

  @doc """
  Gets a zone by slug.
  """
  def get_zone_by_slug(slug) do
    Repo.get_by(Zone, slug: slug)
  end

  @doc """
  Creates a zone.
  """
  def create_zone(attrs \\ %{}) do
    %Zone{}
    |> Zone.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a zone.
  """
  def update_zone(%Zone{} = zone, attrs) do
    zone
    |> Zone.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a zone.
  """
  def delete_zone(%Zone{} = zone) do
    Repo.delete(zone)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking zone changes.
  """
  def change_zone(%Zone{} = zone, attrs \\ %{}) do
    Zone.changeset(zone, attrs)
  end

  # Room functions

  @doc """
  Returns the list of rooms.
  """
  def list_rooms do
    Repo.all(Room)
  end

  @doc """
  Returns all rooms in a specific zone.
  """
  def list_rooms_by_zone(zone_id) do
    Repo.all(from r in Room, where: r.zone_id == ^zone_id)
  end

  @doc """
  Returns all rooms with preloaded associations.
  """
  def get_all_rooms do
    Repo.all(Room)
  end

  @doc """
  Gets a single room by ID.
  """
  def get_room!(id) do
    Repo.get!(Room, id)
  end

  @doc """
  Gets a room by coordinates within a specific zone.
  """
  def get_room_by_coordinates(zone_id, x, y, z \\ 0) do
    Repo.get_by(Room, zone_id: zone_id, x_coordinate: x, y_coordinate: y, z_coordinate: z)
  end

  @doc """
  Gets a room by coordinates (legacy function for backwards compatibility).
  Returns the first match if multiple zones have rooms at the same coordinates.
  """
  def get_room_by_coordinates_legacy(x, y, z \\ 0) do
    Repo.one(
      from r in Room,
        where: r.x_coordinate == ^x and r.y_coordinate == ^y and r.z_coordinate == ^z,
        limit: 1
    )
  end

  @doc """
  Creates a room.
  """
  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.
  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.
  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.
  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  @doc """
  Returns the list of doors.
  """
  def list_doors do
    Repo.all(Door)
  end

  @doc """
  Gets a single door by ID.
  """
  def get_door!(id) do
    Repo.get!(Door, id)
  end

  @doc """
  Creates a door between two rooms.
  Creates a return door automatically.
  """
  def create_door(attrs \\ %{}) do
    changeset = Door.changeset(%Door{}, attrs)

    case changeset.valid? do
      true -> create_door_with_transaction(changeset, attrs)
      false -> {:error, changeset}
    end
  end

  defp create_door_with_transaction(changeset, attrs) do
    Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, door} -> create_return_door_if_needed(door, attrs)
        {:error, main_door_changeset} -> Repo.rollback(main_door_changeset)
      end
    end)
  end

  defp create_return_door_if_needed(door, attrs) do
    return_attrs = build_return_door_attrs(door, attrs)

    case find_existing_return_door(return_attrs) do
      nil -> attempt_return_door_creation(door, return_attrs)
      _existing -> door
    end
  end

  defp build_return_door_attrs(door, attrs) do
    %{
      from_room_id: door.to_room_id,
      to_room_id: door.from_room_id,
      direction: Door.opposite_direction(attrs[:direction]),
      door_type: attrs[:door_type] || "standard",
      is_locked: attrs[:is_locked] || false,
      key_required: attrs[:key_required]
    }
  end

  defp find_existing_return_door(return_attrs) do
    Repo.one(
      from d in Door,
        where:
          d.from_room_id == ^return_attrs[:from_room_id] and
            d.to_room_id == ^return_attrs[:to_room_id] and
            d.direction == ^return_attrs[:direction]
    )
  end

  defp attempt_return_door_creation(door, return_attrs) do
    case %Door{} |> Door.changeset(return_attrs) |> Repo.insert() do
      {:ok, _return_door} -> door
      {:error, _changeset} -> door
    end
  end

  @doc """
  Updates a door.
  """
  def update_door(%Door{} = door, attrs) do
    door
    |> Door.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a door and its corresponding return door.
  """
  def delete_door(%Door{} = door) do
    Repo.transaction(fn ->
      # Find and delete the return door
      return_door = get_return_door(door)

      if return_door do
        Repo.delete!(return_door)
      end

      # Delete the main door
      Repo.delete!(door)
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking door changes.
  """
  def change_door(%Door{} = door, attrs \\ %{}) do
    Door.changeset(door, attrs)
  end

  @doc """
  Gets all doors leading from a specific room.
  """
  def get_doors_from_room(room_id) do
    Repo.all(from d in Door, where: d.from_room_id == ^room_id)
  end

  @doc """
  Gets all doors leading to a specific room.
  """
  def get_doors_to_room(room_id) do
    Repo.all(from d in Door, where: d.to_room_id == ^room_id)
  end

  @doc """
  Finds a door in a specific direction from a room.
  """
  def get_door_in_direction(from_room_id, direction) do
    Repo.one(
      from d in Door,
        where: d.from_room_id == ^from_room_id and d.direction == ^direction
    )
  end

  @doc """
  Gets adjacent rooms (connected by doors) to a given room.
  """
  def get_adjacent_rooms(room_id) do
    # Get rooms that this room leads to
    to_rooms_query =
      from d in Door,
        join: r in assoc(d, :to_room),
        where: d.from_room_id == ^room_id,
        select: r

    # Get rooms that lead to this room
    from_rooms_query =
      from d in Door,
        join: r in assoc(d, :from_room),
        where: d.to_room_id == ^room_id,
        select: r

    # Combine queries
    combined_query =
      from r in subquery(to_rooms_query),
        union: ^from_rooms_query

    Repo.all(combined_query)
  end

  @doc """
  Puts an action on a changeset for form handling.
  """
  def put_action(changeset, action) do
    Map.put(changeset, :action, action)
  end

  @doc """
  Gets the return door for a given door.
  """
  def get_return_door(door) do
    Repo.one(
      from d in Door,
        where:
          d.from_room_id == ^door.to_room_id and
            d.to_room_id == ^door.from_room_id and
            d.direction == ^Door.opposite_direction(door.direction)
    )
  end

  @doc """
  Checks if moving between two rooms represents completing the dungeon.
  Returns a completion message if the movement is from (2,2) to (2,1).
  """
  def check_dungeon_completion(from_room, to_room) do
    with %Room{x_coordinate: 2, y_coordinate: 2} <- from_room,
         %Room{x_coordinate: 2, y_coordinate: 1} <- to_room do
      {:completed, "Congratulations! You have completed the dungeon!"}
    else
      _ -> :no_completion
    end
  end
end
