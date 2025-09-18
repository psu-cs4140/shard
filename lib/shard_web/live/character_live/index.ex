defmodule ShardWeb.CharacterLive.Index do
  use ShardWeb, :live_view

  alias Shard.Characters

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
            # TODO: Update character location in database
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
    current_location = character.location || "starting_room"
    
    # Mock room/door validation - replace with actual map logic
    case {current_location, direction} do
      {"starting_room", "north"} -> {:ok, "forest_entrance"}
      {"starting_room", "east"} -> {:ok, "village_square"}
      {"starting_room", "south"} -> {:error, "A large boulder blocks your path"}
      {"starting_room", "west"} -> {:error, "The door is locked and requires a key"}
      {"forest_entrance", "south"} -> {:ok, "starting_room"}
      {"forest_entrance", _} -> {:error, "Dense trees block your way"}
      {"village_square", "west"} -> {:ok, "starting_room"}
      {"village_square", _} -> {:error, "You cannot go that way"}
      {_, _} -> {:error, "Unknown location or invalid direction"}
    end
  end
end
