defmodule ShardWeb.CharacterLive.Index do
  use ShardWeb, :live_view

  alias Shard.Characters
  alias Shard.Map, as: GameMap

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(user.id)

    {:ok,
     socket
     |> assign(:characters, characters)
     |> assign(:current_scope, socket.assigns.current_scope)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info({:character_created, _character}, socket) do
    user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(user.id)
    {:noreply, assign(socket, :characters, characters)}
  end

  @impl true
  def handle_event("keydown", %{"key" => key}, socket) do
    case key do
      "ArrowUp" -> attempt_move(socket, "north")
      "ArrowDown" -> attempt_move(socket, "south")
      "ArrowLeft" -> attempt_move(socket, "west")
      "ArrowRight" -> attempt_move(socket, "east")
      # Add support for diagonal movement via keyboard combinations
      # These would need to be handled by JavaScript for key combinations
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("diagonal_move", %{"direction" => direction}, socket) do
    case direction do
      "northeast" -> attempt_move(socket, "northeast")
      "northwest" -> attempt_move(socket, "northwest")
      "southeast" -> attempt_move(socket, "southeast")
      "southwest" -> attempt_move(socket, "southwest")
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    character = Characters.get_character!(id)
    user = socket.assigns.current_scope.user

    # Ensure the character belongs to the current user
    if character.user_id == user.id do
      {:ok, _} = Characters.delete_character(character)
      characters = Characters.get_characters_by_user(user.id)

      {:noreply,
       socket
       |> put_flash(:info, "Character deleted successfully")
       |> assign(:characters, characters)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You can only delete your own characters")}
    end
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Characters")
    |> refresh_characters()
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Character")
    |> assign(:character, %Shard.Characters.Character{})
  end

  defp refresh_characters(socket) do
    user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(user.id)
    assign(socket, :characters, characters)
  end

  defp attempt_move(socket, direction) do
    user = socket.assigns.current_scope.user

    # Get the user's active character
    case get_active_character(user.id) do
      nil ->
        IO.puts("Movement failed: No active character selected")
        {:noreply, socket}

      character ->
        case validate_movement(character, direction) do
          {:ok, new_location} ->
            IO.puts("Player moved #{direction} to #{new_location}")
            # Update character location in database
            {:noreply, socket}

          {:error, reason} ->
            IO.puts("Movement failed: #{reason}")
            {:noreply, socket}
        end
    end
  end

  defp get_active_character(user_id) do
    # For now, get the first character. In a real game, you'd track which character is active
    case Characters.get_characters_by_user(user_id) do
      [character | _] -> character
      [] -> nil
    end
  end

  defp validate_movement(character, direction) do
    # Get current room based on character location
    current_room =
      case character.location do
        # Default starting position
        nil ->
          GameMap.get_room_by_coordinates(character.current_zone_id || 1, 0, 0, 0)

        location_string ->
          # Try to parse coordinates from location string or find by name
          case parse_location_coordinates(location_string) do
            {x, y} -> GameMap.get_room_by_coordinates(character.current_zone_id || 1, x, y, 0)
            # Fallback
            nil -> GameMap.get_room_by_coordinates(character.current_zone_id || 1, 0, 0, 0)
          end
      end

    case current_room do
      nil ->
        {:error, "You are in an unknown location"}

      room ->
        # Check if there's a door in the specified direction
        door = GameMap.get_door_in_direction(room.id, direction)

        case door do
          nil -> {:error, "There is no passage in that direction"}
          door -> validate_door_passage(door, room)
        end
    end
  end

  defp parse_location_coordinates(location_string) do
    # Try to extract coordinates from location string like "{1,2}" or "room_1_2"
    case Regex.run(~r/\{(\d+),(\d+)\}/, location_string) do
      [_, x_str, y_str] ->
        {String.to_integer(x_str), String.to_integer(y_str)}

      nil ->
        case Regex.run(~r/room_(\d+)_(\d+)/, location_string) do
          [_, x_str, y_str] ->
            {String.to_integer(x_str), String.to_integer(y_str)}

          nil ->
            nil
        end
    end
  end

  defp validate_door_passage(door, _current_room) do
    cond do
      door.is_locked and door.key_required ->
        {:error, "The #{door.door_type} is locked and requires a #{door.key_required}"}

      door.is_locked ->
        {:error, "The #{door.door_type} is locked"}

      door.door_type == "secret" ->
        # Secret doors need to be discovered
        {:error, "You don't notice any passage here"}

      true ->
        # Get destination room
        case GameMap.get_room!(door.to_room_id) do
          target_room ->
            location_name =
              target_room.name || "{#{target_room.x_coordinate},#{target_room.y_coordinate}}"

            {:ok, location_name}
        end
    end
  end
end
