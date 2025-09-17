defmodule ShardWeb.CharacterLive.Index do
  use ShardWeb, :live_view

  alias Shard.Characters

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    characters = Characters.get_characters_by_user(user.id)
    
    {:ok, assign(socket, :characters, characters)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "My Characters")
  end
end
