defmodule ShardWeb.UserLive.AdminZoneEditor do
  @moduledoc """
  Module for handling admin zone editing commands like creating/deleting rooms and doors.
  """

  alias Shard.Map, as: GameMap

  # Create a room in the specified direction
  def create_room_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    # Get current room
    current_room = GameMap.get_room_by_coordinates(zone_id, x, y, 0)

    case current_room do
      nil ->
        {["You must be in a valid room to create new rooms."], game_state}

      _ ->
        # Calculate new room coordinates based on direction
        {new_x, new_y} = calculate_coordinates_from_direction({x, y}, direction)

        # Check if room already exists at those coordinates
        existing_room = GameMap.get_room_by_coordinates(zone_id, new_x, new_y, 0)

        case existing_room do
          nil ->
            # Room doesn't exist, create the new room with default description
            case GameMap.create_room(%{
                   name: "New Room",
                   description: "A newly created room",
                   x_coordinate: new_x,
                   y_coordinate: new_y,
                   z_coordinate: 0,
                   zone_id: zone_id
                 }) do
              {:ok, new_room} ->
                # Create door from current room to new room
                case GameMap.create_door(%{
                       from_room_id: current_room.id,
                       to_room_id: new_room.id,
                       direction: direction
                     }) do
                  {:ok, _door} ->
                    {[
                       "Successfully created a new room to the #{direction}.",
                       "A door has been created connecting the rooms."
                     ], game_state}

                  {:error, _changeset} ->
                    # Clean up the room if door creation fails
                    GameMap.delete_room(new_room)
                    {["Failed to create door to new room."], game_state}
                end

              {:error, _changeset} ->
                {["Failed to create new room."], game_state}
            end

          _ ->
            {["A room already exists in that direction."], game_state}
        end
    end
  end

  # Delete a room in the specified direction
  def delete_room_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    # Get current room
    current_room = GameMap.get_room_by_coordinates(zone_id, x, y, 0)

    case current_room do
      nil ->
        {["You must be in a valid room to delete rooms."], game_state}

      _ ->
        # Calculate coordinates based on direction
        {target_x, target_y} = calculate_coordinates_from_direction({x, y}, direction)

        # Find room in that direction
        target_room = GameMap.get_room_by_coordinates(zone_id, target_x, target_y, 0)

        case target_room do
          nil ->
            {["There is no room in that direction to delete."], game_state}

          room ->
            # Check if this is the starting room or a critical room
            # For now, we'll allow deletion but could add restrictions
            case GameMap.delete_room(room) do
              {:ok, _} ->
                {["Successfully deleted the room to the #{direction}."], game_state}

              {:error, _} ->
                {["Failed to delete the room."], game_state}
            end
        end
    end
  end

  # Create a door in the specified direction
  def create_door_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    # Get current room
    current_room = GameMap.get_room_by_coordinates(zone_id, x, y, 0)

    case current_room do
      nil ->
        {["You must be in a valid room to create doors."], game_state}

      _ ->
        # Calculate coordinates based on direction
        {target_x, target_y} = calculate_coordinates_from_direction({x, y}, direction)

        # Find room in that direction
        target_room = GameMap.get_room_by_coordinates(zone_id, target_x, target_y, 0)

        case target_room do
          nil ->
            {["There is no room in that direction to create a door to."], game_state}

          room ->
            # Check if door already exists
            existing_door = GameMap.get_door_in_direction(current_room.id, direction)

            case existing_door do
              nil ->
                # Door doesn't exist, create it
                case GameMap.create_door(%{
                       from_room_id: current_room.id,
                       to_room_id: room.id,
                       direction: direction
                     }) do
                  {:ok, _door} ->
                    {["Successfully created a door to the #{direction}."], game_state}

                  {:error, _changeset} ->
                    {["Failed to create door."], game_state}
                end

              _ ->
                {["A door already exists in that direction."], game_state}
            end
        end
    end
  end

  # Delete a door in the specified direction
  def delete_door_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    # Get current room
    current_room = GameMap.get_room_by_coordinates(zone_id, x, y, 0)

    case current_room do
      nil ->
        {["You must be in a valid room to delete doors."], game_state}

      _ ->
        # Check if door exists in that direction
        door = GameMap.get_door_in_direction(current_room.id, direction)

        case door do
          nil ->
            {["There is no door in that direction to delete."], game_state}

          _ ->
            # Door exists, delete it
            case GameMap.delete_door(door) do
              {:ok, _} ->
                {["Successfully deleted the door to the #{direction}."], game_state}

              {:error, _} ->
                {["Failed to delete the door."], game_state}
            end
        end
    end
  end

  # Calculate coordinates based on direction
  defp calculate_coordinates_from_direction({x, y}, direction) do
    case String.downcase(direction) do
      "north" -> {x, y - 1}
      "south" -> {x, y + 1}
      "east" -> {x + 1, y}
      "west" -> {x - 1, y}
      "northeast" -> {x + 1, y - 1}
      "northwest" -> {x - 1, y - 1}
      "southeast" -> {x + 1, y + 1}
      "southwest" -> {x - 1, y + 1}
      # Default to current position for invalid directions
      _ -> {x, y}
    end
  end
end
