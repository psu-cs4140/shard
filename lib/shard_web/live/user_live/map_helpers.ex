# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule ShardWeb.UserLive.MapHelpers do
  @moduledoc false
  alias Shard.Map, as: GameMap
  alias Shard.Npcs.Npc
  alias Shard.Quests.Quest
  alias Shard.Repo

  import Ecto.Query

  # Helper function to generate map data from database
  def generate_map_from_database(zone_id) when is_integer(zone_id) do
    # Get rooms for the specified zone
    rooms = GameMap.list_rooms_by_zone(zone_id)

    # If no rooms exist in this zone, return a default map
    if Enum.empty?(rooms) do
      generate_default_map(zone_id)
    else
      # Find the bounds of all rooms
      {min_x, max_x} =
        rooms
        |> Enum.map(& &1.x_coordinate)
        |> Enum.filter(&(&1 != nil))
        |> case do
          [] -> {0, 10}
          coords -> Enum.min_max(coords)
        end

      {min_y, max_y} =
        rooms
        |> Enum.map(& &1.y_coordinate)
        |> Enum.filter(&(&1 != nil))
        |> case do
          [] -> {0, 10}
          coords -> Enum.min_max(coords)
        end

      # Add padding around the map
      min_x = min_x - 1
      max_x = max_x + 1
      min_y = min_y - 1
      max_y = max_y + 1

      # Create a map of room coordinates for quick lookup
      room_map =
        rooms
        |> Enum.filter(fn room -> room.x_coordinate != nil and room.y_coordinate != nil end)
        |> Enum.into(%{}, fn room -> {{room.x_coordinate, room.y_coordinate}, room} end)

      # Generate the grid
      for y <- min_y..max_y do
        for x <- min_x..max_x do
          case room_map[{x, y}] do
            # Wall/empty space
            nil ->
              0

            room ->
              case room.room_type do
                # Treasure room
                "treasure" -> 3
                # Water room
                "water" -> 2
                # Regular floor
                _ -> 1
              end
          end
        end
      end
    end
  end

  # Fallback function for when no rooms exist in database
  def generate_default_map(map_id \\ "tutorial_terrain") do
    case map_id do
      "tutorial_terrain" ->
        # Generate a simple tutorial map
        for y <- 0..10 do
          for x <- 0..10 do
            cond do
              # Starting position where Goldie is - must be floor
              x == 0 and y == 0 -> 1
              # Walls around the edges (except starting position)
              x == 0 or y == 0 or x == 10 or y == 10 -> 0
              # Treasure in the center
              x == 5 and y == 5 -> 3
              # Central room floor
              x > 3 and x < 7 and y > 3 and y < 7 -> 1
              # Scattered floor tiles for tutorial
              rem(x + y, 4) == 0 -> 1
              # Walls for tutorial simplicity
              true -> 0
            end
          end
        end

      _ ->
        # Default fallback map for any other map_id
        for y <- 0..10 do
          for x <- 0..10 do
            cond do
              # Walls around the edges
              x == 0 or y == 0 or x == 10 or y == 10 -> 0
              # Treasure in the center
              x == 5 and y == 5 -> 3
              # Central room floor
              x > 3 and x < 7 and y > 3 and y < 7 -> 1
              # Water at intervals
              rem(x, 3) == 0 and rem(y, 3) == 0 -> 2
              # Default floor
              true -> 1
            end
          end
        end
    end
  end

  # Find a valid starting position on the map (first non-wall tile)
  def find_valid_starting_position(_map_data) do
    # For tutorial terrain, always start at {0,0} where Goldie is
    {0, 0}
  end

  # Generate a position that is not where the player started
  # Claude helped write this one
  def find_valid_monster_position(map_data, starting_position) do
    # Find all floor tiles (value == 1) in the map
    valid_positions =
      map_data
      # Get {row, y_index}
      |> Enum.with_index()
      |> Enum.flat_map(fn {row, y_index} ->
        row
        # Get {cell_value, x_index}
        |> Enum.with_index()
        # Only floor tiles
        |> Enum.filter(fn {cell_value, _x_index} -> cell_value == 1 end)
        # Convert to {x, y}
        |> Enum.map(fn {_cell_value, x_index} -> {x_index, y_index} end)
      end)
      # Exclude starting position
      |> Enum.filter(fn position -> position != starting_position end)

    # Return a random valid position, or fallback if none found
    case valid_positions do
      [] ->
        # Fallback: place monster at a default position if no valid positions found
        IO.warn("No valid monster positions found, using fallback position")
        {1, 1}

      positions ->
        Enum.random(positions)
    end
  end

  # Helper function to get NPCs at a specific location
  def get_npcs_at_location(x, y, _map_id) do
    # Query database for NPCs at the specified coordinates
    npcs =
      from(n in Npc,
        where: n.location_x == ^x and n.location_y == ^y and n.is_active == true
      )
      |> Repo.all()

    npcs
  end

  # Helper function to get quests by giver NPC ID
  def get_quests_by_giver_npc(npc_id) do
    from(q in Quest,
      where: q.giver_npc_id == ^npc_id and q.is_active == true,
      order_by: [asc: q.sort_order, asc: q.id]
    )
    |> Repo.all()
  end

  # Helper function to get quests by giver NPC ID excluding completed ones
  def get_quests_by_giver_npc_excluding_completed(npc_id, user_id) do
    try do
      # Use the proper database function to exclude completed quests
      Shard.Quests.get_available_quests_by_giver_excluding_completed(user_id, npc_id)
    rescue
      _ ->
        # Fallback to basic quest query if the function doesn't exist or fails
        from(q in Quest,
          where: q.giver_npc_id == ^npc_id and q.is_active == true and q.status == "available",
          order_by: [asc: q.sort_order, asc: q.id]
        )
        |> Repo.all()
    end
  end

  # Helper function to check if a quest has been completed by the user
  def quest_completed_by_user_in_game_state?(quest_id, _game_state) do
    try do
      # Use a mock user_id of 1 for now - in a real implementation,
      # this should come from the current user session
      user_id = 1
      Shard.Quests.quest_completed_by_user?(user_id, quest_id)
    rescue
      _ -> false
    end
  end

  # Helper function to get monsters at a specific location from database
  def get_monsters_at_location(x, y, zone_id) do
    try do
      # First try to find a room at these coordinates
      case Shard.Map.get_room_by_coordinates(zone_id, x, y, 0) do
        nil ->
          []

        room ->
          # Get monsters in this room
          Shard.Monsters.get_monsters_by_location(room.id)
      end
    rescue
      _ -> []
    end
  end
end
