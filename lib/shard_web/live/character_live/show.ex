defmodule ShardWeb.CharacterLive.Show do
  use ShardWeb, :live_view

  alias Shard.Characters

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    character = Characters.get_character!(id)
    user = socket.assigns.current_scope.user

    # Ensure the character belongs to the current user
    if character.user_id == user.id do
      {:noreply,
       socket
       |> assign(:page_title, character.name)
       |> assign(:character, character)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You can only view your own characters")
       |> push_navigate(to: ~p"/characters")}
    end
  end
end
