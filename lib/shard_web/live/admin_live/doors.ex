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

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Doors
      <:actions>
        <.link patch={~p"/admin/doors/new"}>
          <.button>New Door</.button>
        </.link>
      </:actions>
    </.header>

    <.table
      id="doors"
      rows={@streams.doors}
      row_click={fn {_id, door} -> JS.navigate(~p"/admin/doors/#{door}/show") end}
    >
      <:col :let={{_id, door}} label="Name"><%= door.name %></:col>
      <:col :let={{_id, door}} label="From Room">
        <%= if door.from_room, do: door.from_room.name, else: "N/A" %>
      </:col>
      <:col :let={{_id, door}} label="To Room">
        <%= if door.to_room, do: door.to_room.name, else: "N/A" %>
      </:col>
      <:col :let={{_id, door}} label="Direction"><%= door.direction %></:col>
      <:col :let={{_id, door}} label="Type"><%= door.door_type %></:col>
      <:col :let={{_id, door}} label="Locked">
        <%= if door.is_locked, do: "Yes", else: "No" %>
      </:col>
      <:action :let={{_id, door}}>
        <div class="sr-only">
          <.link navigate={~p"/admin/doors/#{door}"}>Show</.link>
        </div>
        <.link patch={~p"/admin/doors/#{door}/edit"}>Edit</.link>
      </:action>
      <:action :let={{id, door}}>
        <.link
          phx-click={JS.push("delete", value: %{id: door.id}) |> hide("##{id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal :if={@live_action in [:new, :edit]} id="door-modal" show on_cancel={JS.patch(~p"/admin/doors")}>
      <.live_component
        module={ShardWeb.AdminLive.DoorFormComponent}
        id={@door.id || :new}
        title={@page_title}
        action={@live_action}
        door={@door}
        patch={~p"/admin/doors"}
      />
    </.modal>
    """
  end
end
