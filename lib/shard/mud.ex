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
  """
  def create_default_grid do
    # Check if we already have rooms
    case Repo.aggregate(Room, :count, :id) do
      0 -> 
        # Create doors first
        doors = create_grid_doors()
        
        # Create rooms and connect them with doors
        create_and_connect_rooms(doors)
      _ -> 
        :ok
    end
  end

  # Create all doors needed for a 3x3 grid
  defp create_grid_doors do
    # For a 3x3 grid, we need:
    # - 6 vertical doors (between columns)
    # - 6 horizontal doors (between rows)
    # Total: 12 doors
    
    doors = for _ <- 1..12 do
      {:ok, door} = create_door(%{is_open: true, is_locked: false, exit: false})
      door
    end
    
    # Also create one exit door
    {:ok, exit_door} = create_door(%{is_open: false, is_locked: true, exit: true})
    
    %{doors: doors, exit_door: exit_door}
  end

  # Create rooms and connect them with doors
  defp create_and_connect_rooms(%{doors: doors, exit_door: exit_door}) do
    # Split doors for horizontal and vertical connections
    {horizontal_doors, vertical_doors} = Enum.split(doors, 6)
    
    # Create 3x3 grid of rooms (9 rooms total)
    rooms_grid = 
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
      |> Enum.group_by(fn {x, y, _room} -> {x, y} end, fn {_x, _y, room} -> room end)
    
    # Connect horizontally adjacent rooms
    connect_horizontal_rooms(rooms_grid, horizontal_doors)
    
    # Connect vertically adjacent rooms
    connect_vertical_rooms(rooms_grid, vertical_doors)
    
    # Add exit door to one room (e.g., room at position (0,0))
    room_0_0 = rooms_grid[{0, 0}] 
    update_room(room_0_0, %{south_door_id: exit_door.id})
    
    :ok
  end

  # Connect horizontally adjacent rooms
  defp connect_horizontal_rooms(rooms_grid, doors) do
    # Group doors into pairs for each row
    door_pairs = Enum.chunk_every(doors, 2)
    
    for y <- 0..2 do
      row_doors = Enum.at(door_pairs, y)
      [left_door, right_door] = row_doors
      
      # Connect rooms in the row
      for x <- 0..1 do
        west_room = rooms_grid[{x, y}]
        east_room = rooms_grid[{x+1, y}]
        
        # Update west room to have east door
        update_room(west_room, %{east_door_id: right_door.id})
        
        # Update east room to have west door
        update_room(east_room, %{west_door_id: right_door.id})
      end
    end
  end

  # Connect vertically adjacent rooms
  defp connect_vertical_rooms(rooms_grid, doors) do
    # Group doors into pairs for each column
    door_pairs = Enum.chunk_every(doors, 2)
    
    for x <- 0..2 do
      col_doors = Enum.at(door_pairs, x)
      [top_door, bottom_door] = col_doors
      
      # Connect rooms in the column
      for y <- 0..1 do
        north_room = rooms_grid[{x, y}]
        south_room = rooms_grid[{x, y+1}]
        
        # Update north room to have south door
        update_room(north_room, %{south_door_id: bottom_door.id})
        
        # Update south room to have north door
        update_room(south_room, %{north_door_id: bottom_door.id})
      end
    end
  end
end
