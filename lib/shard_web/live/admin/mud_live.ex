defmodule ShardWeb.Admin.MudLive do
  use ShardWeb, :live_view

  alias Shard.Mud
  alias Shard.Mud.{Room, Door}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-4xl">
        <.header>
          MUD Management
          <:subtitle>Manage rooms and doors for the MUD game</:subtitle>
        </.header>

        <div class="tabs tabs-lifted mt-6">
          <button
            type="button"
            class={["tab", @active_tab == :rooms && "tab-active"]}
            phx-click="set_tab"
            phx-value-tab="rooms"
          >
            Rooms
          </button>
          <button
            type="button"
            class={["tab", @active_tab == :doors && "tab-active"]}
            phx-click="set_tab"
            phx-value-tab="doors"
          >
            Doors
          </button>
        </div>

        <div class="mt-6">
          <%= if @active_tab == :rooms do %>
            <.rooms_tab rooms={@rooms} room_changeset={@room_changeset} />
          <% end %>

          <%= if @active_tab == :doors do %>
            <.doors_tab doors={@doors} door_changeset={@door_changeset} rooms={@rooms} />
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp rooms_tab(assigns) do
    ~H"""
    <div>
      <.header>
        Rooms
        <:actions>
          <.button phx-click="new_room">New Room</.button>
        </:actions>
      </.header>

      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Description</th>
              <th>North Door</th>
              <th>East Door</th>
              <th>South Door</th>
              <th>West Door</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={room <- @rooms}>
              <td>{room.id}</td>
              <td>{room.name}</td>
              <td>{room.description}</td>
              <td>{room.north_door_id}</td>
              <td>{room.east_door_id}</td>
              <td>{room.south_door_id}</td>
              <td>{room.west_door_id}</td>
              <td class="flex gap-2">
                <.button phx-click="edit_room" phx-value-id={room.id} class="btn-sm">Edit</.button>
                <.button phx-click="delete_room" phx-value-id={room.id} class="btn-sm btn-error">Delete</.button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div :if={@room_changeset} class="mt-6">
        <.header>
          <%= if @room_changeset.data.id do %>
            Edit Room
          <% else %>
            New Room
          <% end %>
        </.header>

        <.form
          for={@room_changeset}
          id="room-form"
          phx-submit="save_room"
          phx-change="validate_room"
        >
          <.input field={@room_changeset[:name]} type="text" label="Name" required />
          <.input field={@room_changeset[:description]} type="textarea" label="Description" />
          
          <div class="grid grid-cols-2 gap-4">
            <.input field={@room_changeset[:north_door_id]} type="select" label="North Door" options={door_options(@doors)} />
            <.input field={@room_changeset[:east_door_id]} type="select" label="East Door" options={door_options(@doors)} />
            <.input field={@room_changeset[:south_door_id]} type="select" label="South Door" options={door_options(@doors)} />
            <.input field={@room_changeset[:west_door_id]} type="select" label="West Door" options={door_options(@doors)} />
          </div>

          <div class="mt-4 flex gap-4">
            <.button phx-disable-with="Saving..." class="btn-primary">
              <%= if @room_changeset.data.id do %>
                Update Room
              <% else %>
                Create Room
              <% end %>
            </.button>
            <.button type="button" phx-click="cancel_room" class="btn-outline">Cancel</.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp doors_tab(assigns) do
    ~H"""
    <div>
      <.header>
        Doors
        <:actions>
          <.button phx-click="new_door">New Door</.button>
        </:actions>
      </.header>

      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>ID</th>
              <th>Open</th>
              <th>Locked</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={door <- @doors}>
              <td>{door.id}</td>
              <td>{if door.is_open, do: "Yes", else: "No"}</td>
              <td>{if door.is_locked, do: "Yes", else: "No"}</td>
              <td class="flex gap-2">
                <.button phx-click="edit_door" phx-value-id={door.id} class="btn-sm">Edit</.button>
                <.button phx-click="delete_door" phx-value-id={door.id} class="btn-sm btn-error">Delete</.button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div :if={@door_changeset} class="mt-6">
        <.header>
          <%= if @door_changeset.data.id do %>
            Edit Door
          <% else %>
            New Door
          <% end %>
        </.header>

        <.form
          for={@door_changeset}
          id="door-form"
          phx-submit="save_door"
          phx-change="validate_door"
        >
          <.input field={@door_changeset[:is_open]} type="checkbox" label="Open" />
          <.input field={@door_changeset[:is_locked]} type="checkbox" label="Locked" />

          <div class="mt-4 flex gap-4">
            <.button phx-disable-with="Saving..." class="btn-primary">
              <%= if @door_changeset.data.id do %>
                Update Door
              <% else %>
                Create Door
              <% end %>
            </.button>
            <.button type="button" phx-click="cancel_door" class="btn-outline">Cancel</.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp door_options(doors) do
    [{"None", nil} | Enum.map(doors, &{&1.id, &1.id})]
  end

  @impl true
  def mount(_params, _session, socket) do
    rooms = Mud.list_rooms()
    doors = Mud.list_doors()

    socket =
      socket
      |> assign(
        active_tab: :rooms,
        rooms: rooms,
        doors: doors,
        room_changeset: nil,
        door_changeset: nil
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_atom(tab))}
  end

  # Room events
  def handle_event("new_room", _, socket) do
    {:noreply, assign(socket, :room_changeset, Mud.change_room(%Room{}))}
  end

  def handle_event("edit_room", %{"id" => id}, socket) do
    room = Mud.get_room!(id)
    changeset = Mud.change_room(room)
    {:noreply, assign(socket, :room_changeset, changeset)}
  end

  def handle_event("cancel_room", _, socket) do
    {:noreply, assign(socket, :room_changeset, nil)}
  end

  def handle_event("validate_room", %{"room" => room_params}, socket) do
    changeset =
      case socket.assigns.room_changeset do
        nil -> Mud.change_room(%Room{}, room_params)
        changeset -> Mud.change_room(changeset.data, room_params)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :room_changeset, changeset)}
  end

  def handle_event("save_room", %{"room" => room_params}, socket) do
    case save_room(socket, room_params) do
      {:ok, room} ->
        rooms = Mud.list_rooms()
        {:noreply,
         socket
         |> put_flash(:info, "Room #{room.name} saved successfully")
         |> assign(:rooms, rooms)
         |> assign(:room_changeset, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :room_changeset, changeset)}
    end
  end

  def handle_event("delete_room", %{"id" => id}, socket) do
    room = Mud.get_room!(id)
    {:ok, _} = Mud.delete_room(room)

    rooms = Mud.list_rooms()
    {:noreply,
     socket
     |> put_flash(:info, "Room deleted successfully")
     |> assign(:rooms, rooms)}
  end

  # Door events
  def handle_event("new_door", _, socket) do
    {:noreply, assign(socket, :door_changeset, Mud.change_door(%Door{}))}
  end

  def handle_event("edit_door", %{"id" => id}, socket) do
    door = Mud.get_door!(id)
    changeset = Mud.change_door(door)
    {:noreply, assign(socket, :door_changeset, changeset)}
  end

  def handle_event("cancel_door", _, socket) do
    {:noreply, assign(socket, :door_changeset, nil)}
  end

  def handle_event("validate_door", %{"door" => door_params}, socket) do
    changeset =
      case socket.assigns.door_changeset do
        nil -> Mud.change_door(%Door{}, door_params)
        changeset -> Mud.change_door(changeset.data, door_params)
      end
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :door_changeset, changeset)}
  end

  def handle_event("save_door", %{"door" => door_params}, socket) do
    case save_door(socket, door_params) do
      {:ok, door} ->
        doors = Mud.list_doors()
        {:noreply,
         socket
         |> put_flash(:info, "Door saved successfully")
         |> assign(:doors, doors)
         |> assign(:door_changeset, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :door_changeset, changeset)}
    end
  end

  def handle_event("delete_door", %{"id" => id}, socket) do
    door = Mud.get_door!(id)
    {:ok, _} = Mud.delete_door(door)

    doors = Mud.list_doors()
    {:noreply,
     socket
     |> put_flash(:info, "Door deleted successfully")
     |> assign(:doors, doors)}
  end

  defp save_room(socket, room_params) do
    case socket.assigns.room_changeset do
      nil ->
        Mud.create_room(room_params)

      changeset ->
        if changeset.data.id do
          Mud.update_room(changeset.data, room_params)
        else
          Mud.create_room(room_params)
        end
    end
  end

  defp save_door(socket, door_params) do
    case socket.assigns.door_changeset do
      nil ->
        Mud.create_door(door_params)

      changeset ->
        if changeset.data.id do
          Mud.update_door(changeset.data, door_params)
        else
          Mud.create_door(door_params)
        end
    end
  end
end
