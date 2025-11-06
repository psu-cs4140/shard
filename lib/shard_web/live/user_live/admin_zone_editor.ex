defmodule ShardWeb.UserLive.AdminZoneEditor do
  @moduledoc """
  Module for handling admin zone editing commands like creating/deleting rooms and doors.
  """

  alias Shard.Map, as: GameMap

  # Create a room in the specified direction
  def create_room_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    with {:ok, _current_room} <- get_current_room(zone_id, x, y),  # Fixed: added underscore to unused variable
         {:ok, new_coordinates} <- calculate_new_coordinates({x, y}, direction),
         nil <- get_existing_room(zone_id, new_coordinates),
         {:ok, new_room} <- create_new_room(zone_id, new_coordinates) do
      create_door_connection(new_room, direction, game_state)
    else
      {:error, reason} -> handle_error(reason, game_state)
      room when not is_nil(room) -> handle_existing_room(game_state)
    end
  end

  # Delete a room in the specified direction
  def delete_room_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    with {:ok, _current_room} <- get_current_room(zone_id, x, y),  # Fixed: added underscore to unused variable
         {:ok, target_coordinates} <- calculate_new_coordinates({x, y}, direction),
         {:ok, target_room} <- get_target_room(zone_id, target_coordinates) do
      delete_target_room(target_room, direction, game_state)
    else
      {:error, reason} -> handle_error(reason, game_state)
    end
  end

  # Create a door in the specified direction
  def create_door_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    with {:ok, current_room} <- get_current_room(zone_id, x, y),
         {:ok, target_coordinates} <- calculate_new_coordinates({x, y}, direction),
         {:ok, target_room} <- get_target_room(zone_id, target_coordinates),
         nil <- get_existing_door(current_room.id, direction) do
      create_door(current_room, target_room, direction, game_state)
    else
      {:error, reason} -> handle_error(reason, game_state)
      door when not is_nil(door) -> handle_existing_door(game_state)
    end
  end

  # Delete a door in the specified direction
  def delete_door_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    with {:ok, current_room} <- get_current_room(zone_id, x, y),
         {:ok, door} <- get_door_to_delete(current_room.id, direction) do
      delete_door(door, direction, game_state)
    else
      {:error, reason} -> handle_error(reason, game_state)
    end
  end

  # Helper functions for create_room_in_direction
  defp get_current_room(zone_id, x, y) do
    case GameMap.get_room_by_coordinates(zone_id, x, y, 0) do
      nil -> {:error, "You must be in a valid room to create new rooms."}
      room -> {:ok, room}
    end
  end

  defp calculate_new_coordinates({x, y}, direction) do
    {new_x, new_y} = calculate_coordinates_from_direction({x, y}, direction)
    {:ok, {new_x, new_y}}
  end

  defp get_existing_room(zone_id, {new_x, new_y}) do
    GameMap.get_room_by_coordinates(zone_id, new_x, new_y, 0)
  end

  defp create_new_room(zone_id, {new_x, new_y}) do
    new_room_name = "Room (#{new_x}, #{new_y})"
    new_room_description = "A newly created room at coordinates (#{new_x}, #{new_y})."

    GameMap.create_room(%{
      name: new_room_name,
      description: new_room_description,
      x_coordinate: new_x,
      y_coordinate: new_y,
      z_coordinate: 0,
      zone_id: zone_id,
      is_public: true,
      room_type: "standard",
      properties: %{}
    })
  end

  defp create_door_connection(new_room, direction, game_state) do
    # Get the current room again since we need it for door creation
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id
    
    case GameMap.get_room_by_coordinates(zone_id, x, y, 0) do
      nil -> 
        # Clean up the room if we can't find the current room
        GameMap.delete_room(new_room)
        {["Failed to create door to new room - current room not found."], game_state}
        
      current_room ->
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
    end
  end

  defp handle_error(reason, game_state) do
    {[reason], game_state}
  end

  defp handle_existing_room(game_state) do
    {["A room already exists in that direction."], game_state}
  end

  # Helper functions for delete_room_in_direction
  defp get_target_room(zone_id, {target_x, target_y}) do
    case GameMap.get_room_by_coordinates(zone_id, target_x, target_y, 0) do
      nil -> {:error, "There is no room in that direction to delete."}
      room -> {:ok, room}
    end
  end

  defp delete_target_room(room, direction, game_state) do
    case GameMap.delete_room(room) do
      {:ok, _} ->
        {["Successfully deleted the room to the #{direction}."], game_state}

      {:error, _} ->
        {["Failed to delete the room."], game_state}
    end
  end

  # Helper functions for create_door_in_direction
  defp get_existing_door(from_room_id, direction) do
    GameMap.get_door_in_direction(from_room_id, direction)
  end

  defp create_door(current_room, target_room, direction, game_state) do
    case GameMap.create_door(%{
           from_room_id: current_room.id,
           to_room_id: target_room.id,
           direction: direction
         }) do
      {:ok, _door} ->
        {["Successfully created a door to the #{direction}."], game_state}

      {:error, _changeset} ->
        {["Failed to create door."], game_state}
    end
  end

  defp handle_existing_door(game_state) do
    {["A door already exists in that direction."], game_state}
  end

  # Helper functions for delete_door_in_direction
  defp get_door_to_delete(from_room_id, direction) do
    case GameMap.get_door_in_direction(from_room_id, direction) do
      nil -> {:error, "There is no door in that direction to delete."}
      door -> {:ok, door}
    end
  end

  defp delete_door(door, direction, game_state) do
    case GameMap.delete_door(door) do
      {:ok, _} ->
        {["Successfully deleted the door to the #{direction}."], game_state}

      {:error, _} ->
        {["Failed to delete the door."], game_state}
    end
  end

  # Calculate coordinates based on direction using a map lookup
  defp calculate_coordinates_from_direction({x, y}, direction) do
    coordinate_map = %{
      "north" => {x, y - 1},
      "south" => {x, y + 1},
      "east" => {x + 1, y},
      "west" => {x - 1, y},
      "northeast" => {x + 1, y - 1},
      "northwest" => {x - 1, y - 1},
      "southeast" => {x + 1, y + 1},
      "southwest" => {x - 1, y + 1}
    }
    
    Map.get(coordinate_map, String.downcase(direction), {x, y})
  end
end
