defmodule Shard.Map do
  @moduledoc """
  The Map context for managing rooms and doors in the MUD game.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Map.{Room, Door}

  @doc """
  Returns the list of rooms.
  """
  def list_rooms do
    Repo.all(Room)
    |> Repo.preload([:doors_from, :doors_to])
  end

  @doc """
  Gets a single room by ID.
  """
  def get_room!(id) do
    Repo.get!(Room, id)
    |> Repo.preload([:doors_from, :doors_to])
  end

  @doc """
  Gets a room by coordinates.
  """
  def get_room_by_coordinates(x, y, z \\ 0) do
    Repo.get_by(Room, x_coordinate: x, y_coordinate: y, z_coordinate: z)
    |> Repo.preload([:doors_from, :doors_to])
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
    |> Repo.preload([:from_room, :to_room])
  end

  @doc """
  Gets a single door by ID.
  """
  def get_door!(id) do
    Repo.get!(Door, id)
    |> Repo.preload([:from_room, :to_room])
  end

  @doc """
  Creates a door between two rooms.
  """
  def create_door(attrs \\ %{}) do
    %Door{}
    |> Door.changeset(attrs)
    |> Repo.insert()
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
  Deletes a door.
  """
  def delete_door(%Door{} = door) do
    Repo.delete(door)
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
    |> Repo.preload([:to_room])
  end

  @doc """
  Gets all doors leading to a specific room.
  """
  def get_doors_to_room(room_id) do
    Repo.all(from d in Door, where: d.to_room_id == ^room_id)
    |> Repo.preload([:from_room])
  end

  @doc """
  Finds a door in a specific direction from a room.
  """
  def get_door_in_direction(from_room_id, direction) do
    Repo.one(
      from d in Door,
        where: d.from_room_id == ^from_room_id and d.direction == ^direction
    )
    |> Repo.preload([:to_room])
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
  Generates a default 3x3 grid map with rooms and connecting doors.
  """
  def generate_default_map do
    # Clear existing rooms and doors first
    Repo.delete_all(Door)
    Repo.delete_all(Room)
    
    # Create a 3x3 grid of rooms
    rooms = 
      for x <- 0..2, y <- 0..2 do
        name = "Room #{x},#{y}"
        description = "A room in the default map at coordinates (#{x}, #{y})"
        room_type = if x == 1 and y == 1, do: "safe_zone", else: "standard"
        
        {:ok, room} = create_room(%{
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
    
    # Create doors between adjacent rooms
    for x <- 0..2, y <- 0..2 do
      current_room = Enum.find(rooms, &(&1.x_coordinate == x and &1.y_coordinate == y))
      
      # Connect to room to the east
      if x < 2 do
        east_room = Enum.find(rooms, &(&1.x_coordinate == x + 1 and &1.y_coordinate == y))
        create_door(%{
          from_room_id: current_room.id,
          to_room_id: east_room.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })
      end
      
      # Connect to room to the south
      if y < 2 do
        south_room = Enum.find(rooms, &(&1.x_coordinate == x and &1.y_coordinate == y + 1))
        create_door(%{
          from_room_id: current_room.id,
          to_room_id: south_room.id,
          direction: "south",
          door_type: "standard",
          is_locked: false
        })
      end
    end
    
    {:ok, "Default 3x3 map generated successfully"}
  end
end
