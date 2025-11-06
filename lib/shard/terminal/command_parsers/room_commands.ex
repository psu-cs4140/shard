defmodule Shard.Terminal.CommandParsers.RoomCommands do
  @moduledoc """
  Parser for room-related commands in the terminal interface.
  """

  alias Shard.Map
  alias Shard.Map.Door

  def parse("look", game_state) do
    room = game_state.current_room
    {:ok, format_room_description(room, game_state)}
  end

  def parse("create room " <> rest, game_state) do
    case String.split(rest, " ", parts: 2) do
      [direction, room_name] ->
        case create_room_in_direction(game_state, direction, room_name) do
          {:ok, message} ->
            {:update_game_state, game_state, message}
            
          {:error, error_message} ->
            {:error, "Room creation failed: #{error_message}"}
        end
        
      [_direction] ->
        {:error, "Please specify both direction and room name: create room <direction> <room_name>"}
        
      _ ->
        {:error, "Invalid syntax. Use: create room <direction> <room_name>"}
    end
  end

  def parse("delete room", game_state) do
    room = game_state.current_room
    
    # Prevent deletion of the starting room or important rooms
    if is_protected_room?(room) do
      {:error, "This room cannot be deleted."}
    else
      case Map.delete_room(room) do
        {:ok, _} ->
          {:update_game_state, game_state, "Room deleted successfully."}
        {:error, _} ->
          {:error, "Failed to delete room."}
      end
    end
  end

  def parse("edit room " <> rest, game_state) do
    case String.split(rest, " ", parts: 2) do
      [field, value] ->
        update_room_field(game_state, field, value)
      _ ->
        {:error, "Invalid syntax. Use: edit room <field> <value>"}
    end
  end

  def parse("link room " <> direction, game_state) do
    case link_room_in_direction(game_state, direction) do
      {:ok, message} ->
        {:update_game_state, game_state, message}
      {:error, error_message} ->
        {:error, error_message}
    end
  end

  def parse("unlink room " <> direction, game_state) do
    case unlink_room_in_direction(game_state, direction) do
      {:ok, message} ->
        {:update_game_state, game_state, message}
      {:error, error_message} ->
        {:error, error_message}
    end
  end

  def parse("move " <> direction, game_state) do
    case move_to_direction(game_state, direction) do
      {:ok, new_game_state} ->
        {:update_game_state, new_game_state, format_room_description(new_game_state.current_room, new_game_state)}
      {:error, message} ->
        {:error, message}
    end
  end

  # Default case for unrecognized commands
  def parse(_command, _game_state) do
    {:error, "Unknown room command. Available commands: look, create room, delete room, edit room, link room, unlink room, move"}
  end

  defp create_room_in_direction(game_state, direction, room_name) do
    current_room = game_state.current_room
    
    # Validate direction
    case validate_direction(direction) do
      :ok -> 
        new_coordinates = calculate_new_coordinates(current_room, direction)
        
        # Check if room already exists at those coordinates
        case Map.get_room_by_coordinates(current_room.zone_id, new_coordinates.x, new_coordinates.y, new_coordinates.z) do
          nil ->
            # Room doesn't exist, proceed with creation
            room_attrs = %{
              name: room_name,
              description: "A newly created room",
              zone_id: current_room.zone_id,
              x_coordinate: new_coordinates.x,
              y_coordinate: new_coordinates.y,
              z_coordinate: new_coordinates.z,
              room_type: "standard",
              is_public: true
            }
            
            case Map.create_room(room_attrs) do
              {:ok, new_room} ->
                # Create door from current room to new room
                # The Map.create_door function will automatically create the return door
                door_attrs = %{
                  from_room_id: current_room.id,
                  to_room_id: new_room.id,
                  direction: direction
                }
                
                case Map.create_door(door_attrs) do
                  {:ok, _door} ->
                    {:ok, "Room '#{room_name}' created to the #{direction} and connected with doors."}
                  {:error, changeset} ->
                    # Log the error but don't fail completely since room was created
                    IO.warn("Failed to create door: #{inspect(changeset.errors)}")
                    {:ok, "Room '#{room_name}' created to the #{direction} but door creation failed."}
                end
                
              {:error, changeset} ->
                {:error, "Failed to create room: #{format_room_errors(changeset)}"}
            end
            
          existing_room ->
            {:error, "A room already exists at that location: #{existing_room.name}"}
        end
        
      {:error, message} ->
        {:error, message}
    end
  end

  defp link_room_in_direction(game_state, direction) do
    current_room = game_state.current_room
    
    # Validate direction
    case validate_direction(direction) do
      :ok ->
        # Calculate target coordinates
        target_coordinates = calculate_new_coordinates(current_room, direction)
        
        # Find existing room at those coordinates
        case Map.get_room_by_coordinates(current_room.zone_id, target_coordinates.x, target_coordinates.y, target_coordinates.z) do
          nil ->
            {:error, "No room exists at #{direction} to link to."}
            
          target_room ->
            # Check if door already exists
            case Map.get_door_in_direction(current_room.id, direction) do
              nil ->
                # Create door from current room to target room
                door_attrs = %{
                  from_room_id: current_room.id,
                  to_room_id: target_room.id,
                  direction: direction
                }
                
                case Map.create_door(door_attrs) do
                  {:ok, _door} ->
                    {:ok, "Rooms linked to the #{direction}."}
                  {:error, changeset} ->
                    {:error, "Failed to link rooms: #{format_door_errors(changeset)}"}
                end
                
              _existing_door ->
                {:error, "A door already exists in that direction."}
            end
        end
        
      {:error, message} ->
        {:error, message}
    end
  end

  defp unlink_room_in_direction(game_state, direction) do
    current_room = game_state.current_room
    
    # Validate direction
    case validate_direction(direction) do
      :ok ->
        # Find existing door in that direction
        case Map.get_door_in_direction(current_room.id, direction) do
          nil ->
            {:error, "No door exists in that direction to unlink."}
            
          door ->
            # Delete the door (Map.delete_door will also delete the return door)
            case Map.delete_door(door) do
              {:ok, _} ->
                {:ok, "Door to the #{direction} unlinked."}
              {:error, _} ->
                {:error, "Failed to unlink door."}
            end
        end
        
      {:error, message} ->
        {:error, message}
    end
  end

  defp move_to_direction(game_state, direction) do
    current_room = game_state.current_room
    
    # Validate direction
    case validate_direction(direction) do
      :ok ->
        # Find door in that direction
        case Map.get_door_in_direction(current_room.id, direction) do
          nil ->
            {:error, "You cannot go #{direction} from here."}
            
          door ->
            # Get the target room
            case Map.get_room!(door.to_room_id) do
              target_room ->
                # Update game state with new room
                new_game_state = %{game_state | current_room: target_room}
                {:ok, new_game_state}
                
              _ ->
                {:error, "The room in that direction doesn't exist."}
            end
        end
        
      {:error, message} ->
        {:error, message}
    end
  end

  defp update_room_field(game_state, field, value) do
    current_room = game_state.current_room
    
    # Convert value based on field type
    attrs = case field do
      "name" -> %{name: value}
      "description" -> %{description: value}
      "room_type" -> %{room_type: value}
      "is_public" -> %{is_public: parse_boolean(value)}
      _ -> %{field => value}
    end
    
    case Map.update_room(current_room, attrs) do
      {:ok, updated_room} ->
        # Update game state with updated room
        new_game_state = %{game_state | current_room: updated_room}
        {:update_game_state, new_game_state, "Room #{field} updated."}
      {:error, changeset} ->
        {:error, "Failed to update room: #{format_room_errors(changeset)}"}
    end
  end

  defp validate_direction(direction) do
    valid_directions = ["north", "south", "east", "west", "up", "down", "northeast", "northwest", "southeast", "southwest"]
    
    if direction in valid_directions do
      :ok
    else
      {:error, "Invalid direction. Valid directions: #{Enum.join(valid_directions, ", ")}"}
    end
  end

  defp calculate_new_coordinates(current_room, direction) do
    case direction do
      "north" -> %{x: current_room.x_coordinate, y: current_room.y_coordinate + 1, z: current_room.z_coordinate}
      "south" -> %{x: current_room.x_coordinate, y: current_room.y_coordinate - 1, z: current_room.z_coordinate}
      "east" -> %{x: current_room.x_coordinate + 1, y: current_room.y_coordinate, z: current_room.z_coordinate}
      "west" -> %{x: current_room.x_coordinate - 1, y: current_room.y_coordinate, z: current_room.z_coordinate}
      "up" -> %{x: current_room.x_coordinate, y: current_room.y_coordinate, z: current_room.z_coordinate + 1}
      "down" -> %{x: current_room.x_coordinate, y: current_room.y_coordinate, z: current_room.z_coordinate - 1}
      "northeast" -> %{x: current_room.x_coordinate + 1, y: current_room.y_coordinate + 1, z: current_room.z_coordinate}
      "northwest" -> %{x: current_room.x_coordinate - 1, y: current_room.y_coordinate + 1, z: current_room.z_coordinate}
      "southeast" -> %{x: current_room.x_coordinate + 1, y: current_room.y_coordinate - 1, z: current_room.z_coordinate}
      "southwest" -> %{x: current_room.x_coordinate - 1, y: current_room.y_coordinate - 1, z: current_room.z_coordinate}
      _ -> %{x: current_room.x_coordinate, y: current_room.y_coordinate, z: current_room.z_coordinate}
    end
  end

  defp format_room_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
    |> Enum.join(", ")
  end

  defp format_door_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
    |> Enum.join(", ")
  end

  defp parse_boolean("true"), do: true
  defp parse_boolean("false"), do: false
  defp parse_boolean(_), do: false

  defp is_protected_room?(room) do
    # Add logic to protect certain rooms from deletion
    # For example, rooms with specific names or IDs
    room.name == "Starting Room" || room.id == 1
  end

  defp format_room_description(room, game_state) do
    doors = Map.get_doors_from_room(room.id)
    door_descriptions = 
      if Enum.empty?(doors) do
        "There are no exits."
      else
        exits = 
          doors 
          |> Enum.map(& &1.direction) 
          |> Enum.join(", ")
        "Exits: #{exits}"
      end
    
    """
    #{room.name}
    #{String.duplicate("-", String.length(room.name))}
    #{room.description}
    
    #{door_descriptions}
    """
  end
end
