defmodule ShardWeb.CharacterLive.Index do
  use ShardWeb, :live_view

  alias Shard.Characters

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_scope.user
    characters = Characters.get_characters_by_user(user.id)
    
    {:ok, assign(socket, :characters, characters)}
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
end
