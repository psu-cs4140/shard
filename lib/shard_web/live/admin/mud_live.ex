defmodule ShardWeb.Admin.MudLive do
  use ShardWeb, :live_view

  alias Shard.Mud
  alias Shard.Mud.{Room, Door}

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-6xl">
        <.header>
          MUD Map Editor
          <:subtitle>Create and manage rooms and doors for the MUD game</:subtitle>
        </.header>

        <div class="tabs tabs-lifted mt-6">
          <button
            type="button"
            class={["tab", @active_tab == :grid && "tab-active"]}
            phx-click="set_tab"
            phx-value-tab="grid"
          >
            Grid View
          </button>
          <button
            type="button"
            class={["tab", @active_tab == :rooms && "tab-active"]}
            phx-click="set_tab"
            phx-value-tab="rooms"
          >
            Rooms List
          </button>
          <button
            type="button"
            class={["tab", @active_tab == :doors && "tab-active"]}
            phx-click="set_tab"
            phx-value-tab="doors"
          >
            Doors List
          </button>
        </div>

        <div class="mt-6">
          <%= if @active_tab == :grid do %>
            <.grid_tab rooms={@rooms} selected_room={@selected_room} doors={@doors} />
          <% end %>

          <%= if @active_tab == :rooms do %>
            <.rooms_tab rooms={@rooms} room_changeset={@room_changeset} doors={@doors} />
          <% end %>

          <%= if @active_tab == :doors do %>
            <.doors_tab doors={@doors} door_changeset={@door_changeset} />
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp grid_tab(assigns) do
    ~H"""
    <div>
      <.header>
        Room Grid
        <:actions>
          <.button phx-click="new_room">New Room</.button>
        </:actions>
      </.header>

      <div class="flex justify-between items-center mb-4">
        <div class="flex items-center gap-2">
          <span class="font-medium">Legend:</span>
          <div class="flex items-center gap-2">
            <div class="w-4 h-4 bg-blue-500 border border-gray-300"></div>
            <span>Room</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="w-4 h-4 bg-green-500"></div>
            <span>Selected</span>
          </div>
          <div class="flex items-center gap-2">
            <div class="w-4 h-1 bg-yellow-500"></div>
            <span>Door</span>
          </div>
        </div>
        <.button phx-click="refresh_grid" class="btn btn-sm">Refresh</.button>
      </div>

      <div class="overflow-auto border rounded-lg bg-gray-100 p-4" style="max-height: 70vh;">
        <div class="relative" style="min-width: 800px; min-height: 600px;">
          <!-- Grid lines -->
          <div class="absolute inset-0 bg-grid-pattern opacity-20"></div>
          
          <!-- Rooms -->
          <%= for room <- @rooms do %>
            <div 
              class={"absolute w-16 h-16 flex items-center justify-center border rounded cursor-pointer #{if @selected_room && @selected_room.id == room.id, do: "bg-green-500 border-green-700", else: "bg-blue-500 border-blue-700"}"}
              style={"top: #{300 - (room.y * 64) - 32}px; left: #{400 + (room.x * 64) - 32}px;"}
              phx-click="select_room"
              phx-value-id={room.id}
            >
              <span class="text-xs font-bold text-white text-center break-words" style="max-width: 60px;"><%= room.name %></span>
            </div>
            
            <!-- Door connections -->
            <%= if room.north_door_id do %>
              <% door = Enum.find(@doors, fn d -> d.id == room.north_door_id end) %>
              <div class={"absolute #{if door && door.is_open, do: "bg-yellow-500", else: "bg-gray-500"}"} 
                   style={"top: #{300 - (room.y * 64) - 32 - 16}px; left: #{400 + (room.x * 64) - 2}px; width: 4px; height: 16px;"}>
              </div>
            <% end %>
            
            <%= if room.east_door_id do %>
              <% door = Enum.find(@doors, fn d -> d.id == room.east_door_id end) %>
              <div class={"absolute #{if door && door.is_open, do: "bg-yellow-500", else: "bg-gray-500"}"} 
                   style={"top: #{300 - (room.y * 64) - 2}px; left: #{400 + (room.x * 64) + 32}px; width: 16px; height: 4px;"}>
              </div>
            <% end %>
            
            <%= if room.south_door_id do %>
              <% door = Enum.find(@doors, fn d -> d.id == room.south_door_id end) %>
              <div class={"absolute #{if door && door.is_open, do: "bg-yellow-500", else: "bg-gray-500"}"} 
                   style={"top: #{300 - (room.y * 64) + 32}px; left: #{400 + (room.x * 64) - 2}px; width: 4px; height: 16px;"}>
              </div>
            <% end %>
            
            <%= if room.west_door_id do %>
              <% door = Enum.find(@doors, fn d -> d.id == room.west_door_id end) %>
              <div class={"absolute #{if door && door.is_open, do: "bg-yellow-500", else: "bg-gray-500"}"} 
                   style={"top: #{300 - (room.y * 64) - 2}px; left: #{400 + (room.x * 64) - 32 - 16}px; width: 16px; height: 4px;"}>
              </div>
            <% end %>
          <% end %>
          
          <!-- Compass directions -->
          <div class="absolute top-0 left-1/2 transform -translate-x-1/2 text-lg font-bold">N</div>
          <div class="absolute right-0 top-1/2 transform -translate-y-1/2 text-lg font-bold">E</div>
          <div class="absolute bottom-0 left-1/2 transform -translate-x-1/2 text-lg font-bold">S</div>
          <div class="absolute left-0 top-1/2 transform -translate-y-1/2 text-lg font-bold">W</div>
        </div>
      </div>

      <%= if @selected_room do %>
        <div class="mt-6 p-4 border rounded-lg bg-base-100">
          <.header>
            <%= @selected_room.name %>
            <:actions>
              <.button phx-click="edit_room" phx-value-id={@selected_room.id} class="btn-sm">Edit</.button>
              <.button phx-click="delete_room" phx-value-id={@selected_room.id} class="btn-sm btn-error">Delete</.button>
            </:actions>
          </.header>
          <div class="mt-2">
            <p><span class="font-semibold">Description:</span> <%= @selected_room.description || "No description" %></p>
            <p><span class="font-semibold">Position:</span> (<%= @selected_room.x %>, <%= @selected_room.y %>)</p>
            <div class="mt-2">
              <span class="font-semibold">Doors:</span>
              <ul class="list-disc pl-5 mt-1">
                <li>North: <%= door_status(@selected_room.north_door_id, @doors) %></li>
                <li>East: <%= door_status(@selected_room.east_door_id, @doors) %></li>
                <li>South: <%= door_status(@selected_room.south_door_id, @doors) %></li>
                <li>West: <%= door_status(@selected_room.west_door_id, @doors) %></li>
              </ul>
            </div>
          </div>
        </div>
      <% end %>
    </div>
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
              <th>Position (X, Y)</th>
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
              <td>({room.x}, {room.y})</td>
              <td>{door_status(room.north_door_id, @doors)}</td>
              <td>{door_status(room.east_door_id, @doors)}</td>
              <td>{door_status(room.south_door_id, @doors)}</td>
              <td>{door_status(room.west_door_id, @doors)}</td>
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
            <.input field={@room_changeset[:x]} type="number" label="X Position" />
            <.input field={@room_changeset[:y]} type="number" label="Y Position" />
          </div>
          
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
        </.actions>
      </.header>

      <div class="overflow-x-auto">
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>ID</th>
              <th>Open</th>
              <th>Locked</th>
              <th>Exit</th>
              <th>Connected Rooms</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={door <- @doors}>
              <td>{door.id}</td>
              <td>{if door.is_open, do: "Yes", else: "No"}</td>
              <td>{if door.is_locked, do: "Yes", else: "No"}</td>
              <td>{if door.exit, do: "Yes", else: "No"}</td>
              <td>{connected_rooms_count(door.id, @rooms)}</td>
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
          <.input field={@door_changeset[:exit]} type="checkbox" label="Exit" />

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

  defp door_status(door_id, doors) do
    if door_id do
      door = Enum.find(doors, &(&1.id == door_id))
      if door do
        if door.is_open, do: "Open", else: "Closed"
      else
        "Unknown"
      end
    else
      "None"
    end
  end

  defp connected_rooms_count(door_id, rooms) do
    count = 
      rooms
      |> Enum.filter(fn room ->
        room.north_door_id == door_id ||
        room.east_door_id == door_id ||
        room.south_door_id == door_id ||
        room.west_door_id == door_id
      end)
      |> length()
    
    "#{count} room(s)"
  end

  @impl true
  def mount(_params, _session, socket) do
    # Create initial room if none exists
    Mud.create_default_grid()
    
    rooms = Mud.list_rooms()
    doors = Mud.list_doors()

    socket =
      socket
      |> assign(
        active_tab: :grid,
        rooms: rooms,
        doors: doors,
        room_changeset: nil,
        door_changeset: nil,
        selected_room: nil
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_atom(tab))}
  end

  def handle_event("refresh_grid", _, socket) do
    rooms = Mud.list_rooms()
    doors = Mud.list_doors()
    {:noreply, assign(socket, rooms: rooms, doors: doors)}
  end

  def handle_event("select_room", %{"id" => id}, socket) do
    room = Mud.get_room!(id)
    {:noreply, assign(socket, :selected_room, room)}
  end

  # Room events
  def handle_event("new_room", _, socket) do
    # Find the next available room number for default name
    room_count = length(socket.assigns.rooms)
    default_name = "Room #{room_count}"
    
    {:noreply, assign(socket, :room_changeset, Mud.change_room(%Room{}, %{name: default_name, x: 0, y: 0}))}
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
      {:ok, _room} ->
        rooms = Mud.list_rooms()
        doors = Mud.list_doors()
        {:noreply,
         socket
         |> put_flash(:info, "Room saved successfully")
         |> assign(:rooms, rooms)
         |> assign(:doors, doors)
         |> assign(:room_changeset, nil)
         |> assign(:selected_room, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :room_changeset, changeset)}
    end
  end

  def handle_event("delete_room", %{"id" => id}, socket) do
    room = Mud.get_room!(id)
    {:ok, _} = Mud.delete_room(room)

    rooms = Mud.list_rooms()
    doors = Mud.list_doors()
    {:noreply,
     socket
     |> put_flash(:info, "Room deleted successfully")
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> assign(:selected_room, nil)}
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
      {:ok, _door} ->
        rooms = Mud.list_rooms()
        doors = Mud.list_doors()
        {:noreply,
         socket
         |> put_flash(:info, "Door saved successfully")
         |> assign(:rooms, rooms)
         |> assign(:doors, doors)
         |> assign(:door_changeset, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :door_changeset, changeset)}
    end
  end

  def handle_event("delete_door", %{"id" => id}, socket) do
    door = Mud.get_door!(id)
    {:ok, _} = Mud.delete_door(door)

    rooms = Mud.list_rooms()
    doors = Mud.list_doors()
    {:noreply,
     socket
     |> put_flash(:info, "Door deleted successfully")
     |> assign(:rooms, rooms)
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
