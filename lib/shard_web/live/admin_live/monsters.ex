defmodule ShardWeb.AdminLive.Monsters do
  use ShardWeb, :live_view

  alias Shard.Monsters
  alias Shard.Monsters.Monster
  alias Shard.Map

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :monsters, Monsters.list_monsters())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Monster")
    |> assign(:monster, Monsters.get_monster!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Monster")
    |> assign(:monster, %Monster{})
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    socket
    |> assign(:page_title, "Show Monster")
    |> assign(:monster, Monsters.get_monster!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Monsters")
    |> assign(:monster, nil)
  end

  @impl true
  def handle_info({ShardWeb.AdminLive.MonsterFormComponent, {:saved, monster}}, socket) do
    {:noreply, stream_insert(socket, :monsters, monster)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    monster = Monsters.get_monster!(id)
    {:ok, _} = Monsters.delete_monster(monster)

    {:noreply, stream_delete(socket, :monsters, monster)}
  end
end
