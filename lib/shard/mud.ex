defmodule Shard.Mud do
  @moduledoc """
  The Mud context.
  """

  import Ecto.Query, warn: false
  alias Shard.Repo

  alias Shard.Mud.{Room, Door}

  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]

  """
  def list_rooms do
    Repo.all(Room)
    |> Repo.preload([:north_door, :east_door, :south_door, :west_door])
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id) do
    Repo.get!(Room, id)
    |> Repo.preload([:north_door, :east_door, :south_door, :west_door])
  end

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  @doc """
  Returns the list of doors.

  ## Examples

      iex> list_doors()
      [%Door{}, ...]

  """
  def list_doors do
    Repo.all(Door)
  end

  @doc """
  Gets a single door.

  Raises `Ecto.NoResultsError` if the Door does not exist.

  ## Examples

      iex> get_door!(123)
      %Door{}

      iex> get_door!(456)
      ** (Ecto.NoResultsError)

  """
  def get_door!(id) do
    Repo.get!(Door, id)
  end

  @doc """
  Creates a door.

  ## Examples

      iex> create_door(%{field: value})
      {:ok, %Door{}}

      iex> create_door(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_door(attrs \\ %{}) do
    %Door{}
    |> Door.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a door.

  ## Examples

      iex> update_door(door, %{field: new_value})
      {:ok, %Door{}}

      iex> update_door(door, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_door(%Door{} = door, attrs) do
    door
    |> Door.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a door.

  ## Examples

      iex> delete_door(door)
      {:ok, %Door{}}

      iex> delete_door(door)
      {:error, %Ecto.Changeset{}}

  """
  def delete_door(%Door{} = door) do
    Repo.delete(door)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking door changes.

  ## Examples

      iex> change_door(door)
      %Ecto.Changeset{data: %Door{}}

  """
  def change_door(%Door{} = door, attrs \\ %{}) do
    Door.changeset(door, attrs)
  end

  @doc """
  Creates a 3x3 grid of rooms with proper door connections.
  Any two rooms share exactly one door, and no door is connected to more than 2 rooms.
  Also creates an exit door connected to one room.
  """
  def create_default_grid do
    # Check if we already have rooms
    case Repo.aggregate(Room, :count, :id) do
      0 -> 
        # Create the 3x3 grid first
        rooms_grid = create_3x3_grid()
        
        # Then create the exit door
        create_exit_door(rooms_grid)
      _ -> 
        :ok
    end
  end

  # Create a 3x3 grid of rooms
  defp create_3x3_grid do
    # Create 9 rooms in a 3x3 grid
    rooms =
      for y <- 0..2, x <- 0..2 do
        name = "Room (#{x}, #{y})"
        description = "A room at position (#{x}, #{y})"
        
        {:ok, room} = create_room(%{
          name: name,
          description: description,
          x: x,
          y: y
        })
        
        {x, y, room}
      end

    # Convert to a map for easy access
    rooms_map = 
      rooms
      |> Enum.map(fn {x, y, room} -> {{x, y}, room} end)
      |> Enum.into(%{})

    # Connect adjacent rooms with doors
    # Horizontal connections (east-west)
    for y <- 0..2, x <- 0..1 do
      west_room = rooms_map[{x, y}]
      east_room = rooms_map[{x+1, y}]
      
      # Create door
      {:ok, door} = create_door(%{is_open: true, is_locked: false, exit: false})
      
      # Update rooms to connect through the door
      update_room(west_room, %{east_door_id: door.id})
      update_room(east_room, %{west_door_id: door.id})
    end

    # Vertical connections (north-south)
    for y <- 0..1, x <- 0..2 do
      north_room = rooms_map[{x, y}]
      south_room = rooms_map[{x, y+1}]
      
      # Create door
      {:ok, door} = create_door(%{is_open: true, is_locked: false, exit: false})
      
      # Update rooms to connect through the door
      update_room(north_room, %{south_door_id: door.id})
      update_room(south_room, %{north_door_id: door.id})
    end

    rooms_map
  end

  # Create an exit door connected to one room
  defp create_exit_door(rooms_grid) do
    # Get the room at position (0,0)
    room = rooms_grid[{0, 0}]
    
    # Create exit door
    {:ok, exit_door} = create_door(%{is_open: false, is_locked: true, exit: true})
    
    # Connect the exit door to the room's south side
    update_room(room, %{south_door_id: exit_door.id})
    
    :ok
  end

  @doc """
  Gets map data for visualization.
  Returns a list of rooms with their positions and door connections.
  """
  def get_map_data do
    rooms = list_rooms()
    
    # Convert rooms to map-friendly format
    Enum.map(rooms, fn room ->
      %{
        id: room.id,
        name: room.name,
        x: room.x,
        y: room.y,
        doors: %{
          north: room.north_door_id && %{
            id: room.north_door_id,
            is_open: room.north_door && room.north_door.is_open,
            is_locked: room.north_door && room.north_door.is_locked,
            exit: room.north_door && room.north_door.exit
          },
          east: room.east_door_id && %{
            id: room.east_door_id,
            is_open: room.east_door && room.east_door.is_open,
            is_locked: room.east_door && room.east_door.is_locked,
            exit: room.east_door && room.east_door.exit
          },
          south: room.south_door_id && %{
            id: room.south_door_id,
            is_open: room.south_door && room.south_door.is_open,
            is_locked: room.south_door && room.south_door.is_locked,
            exit: room.south_door && room.south_door.exit
          },
          west: room.west_door_id && %{
            id: room.west_door_id,
            is_open: room.west_door && room.west_door.is_open,
            is_locked: room.west_door && room.west_door.is_locked,
            exit: room.west_door && room.west_door.exit
          }
        }
      }
    end)
  end
end
