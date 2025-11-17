defmodule ShardWeb.HomeLive do
  use ShardWeb, :live_view

  alias Shard.Characters

  on_mount {ShardWeb.UserAuth, :mount_current_scope}

  @impl true
  def mount(_params, _session, socket) do
    # Get current scope from session or assigns
    current_scope = socket.assigns[:current_scope]

    if current_scope && current_scope.user do
      characters = Characters.get_characters_by_user(current_scope.user.id)

      {:ok,
       socket
       |> assign(:characters, characters)
       |> assign(:show_character_selection, false)
       |> assign(:current_scope, current_scope)}
    else
      {:ok,
       socket
       |> assign(:characters, [])
       |> assign(:show_character_selection, false)
       |> assign(:current_scope, nil)}
    end
  end

  @impl true
  def handle_event("show_character_selection", _params, socket) do
    {:noreply, assign(socket, :show_character_selection, true)}
  end

  @impl true
  def handle_event("hide_character_selection", _params, socket) do
    {:noreply, assign(socket, :show_character_selection, false)}
  end

  @impl true
  def handle_event("select_character", %{"character-id" => character_id}, socket) do
    {:noreply,
     socket
     |> assign(:show_character_selection, false)
     |> push_navigate(to: ~p"/zones?character_id=#{character_id}")}
  end
end
