defmodule ShardWeb.AdminLive.Doors do
  use ShardWeb, :live_view

  alias Shard.Map
  alias Shard.Map.Door

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :doors, Map.list_doors())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Door")
    |> assign(:door, Map.get_door!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Door")
    |> assign(:door, %Door{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Doors")
    |> assign(:door, nil)
  end

  @impl true
  def handle_info({ShardWeb.AdminLive.DoorFormComponent, {:saved, door}}, socket) do
    {:noreply, stream_insert(socket, :doors, door)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    door = Map.get_door!(id)
    {:ok, _} = Map.delete_door(door)

    {:noreply, stream_delete(socket, :doors, door)}
  end
end
