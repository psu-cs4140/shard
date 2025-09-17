defmodule ShardWeb.AdminLive.Characters do
  use ShardWeb, :live_view

  alias Shard.Characters
  alias Shard.Characters.Character
  alias Shard.Users

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :characters, Characters.list_characters())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Character")
    |> assign(:character, Characters.get_character!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Character")
    |> assign(:character, %Character{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Characters")
    |> assign(:character, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Character Details")
    |> assign(:character, Characters.get_character!(id))
  end

  @impl true
  def handle_info({ShardWeb.AdminLive.Characters, {:saved, character}}, socket) do
    {:noreply, stream_insert(socket, :characters, character)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    character = Characters.get_character!(id)
    {:ok, _} = Characters.delete_character(character)

    {:noreply, stream_delete(socket, :characters, character)}
  end
end
