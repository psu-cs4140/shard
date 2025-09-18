defmodule ShardWeb.AdminLive.Map do
  use ShardWeb, :live_view

  alias Shard.Map
  alias Shard.Map.{Room, Door}

  @impl true
  def mount(_params, _session, socket) do
    rooms = Map.list_rooms()
    doors = Map.list_doors()
    
    {:ok,
     socket
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> assign(:page_title, "Map Management")
     |> assign(:tab, "rooms")
     |> assign(:changeset, nil)
     |> assign(:editing, nil)
     |> assign(:zoom, 1.0)
     |> assign(:pan_x, 0)
     |> assign(:pan_y, 0)
     |> assign(:drag_start, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Map Management")
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :tab, tab)}
  end

  # Room events
  def handle_event("new_room", _params, socket) do
    changeset = Map.change_room(%Room{})
    {:noreply, assign(socket, :changeset, changeset) |> assign(:editing, :room)}
  end

  def handle_event("edit_room", %{"id" => id}, socket) do
    room = Map.get_room!(id)
    changeset = Map.change_room(room)
    {:noreply, assign(socket, :changeset, changeset) |> assign(:editing, :room)}
  end

  def handle_event("delete_room", %{"id" => id}, socket) do
    room = Map.get_room!(id)
    {:ok, _} = Map.delete_room(room)
    
    rooms = Map.list_rooms()
    doors = Map.list_doors()
    
    {:noreply,
     socket
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> put_flash(:info, "Room deleted successfully")}
  end

  def handle_event("validate_room", %{"room" => room_params}, socket) do
    changeset = 
      if socket.assigns.editing == :room && socket.assigns.changeset.data.id do
        Map.change_room(socket.assigns.changeset.data, room_params)
      else
        Map.change_room(%Room{}, room_params)
      end
      |> Map.put(:action, :validate)
    
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save_room", %{"room" => room_params}, socket) do
    case save_room(socket, room_params) do
      {:ok, socket} -> {:noreply, socket}
      {:error, socket} -> {:noreply, socket}
    end
  end

  def handle_event("cancel_room", _params, socket) do
    {:noreply, assign(socket, :editing, nil) |> assign(:changeset, nil)}
  end

  # Door events
  def handle_event("new_door", _params, socket) do
    changeset = Map.change_door(%Door{})
    {:noreply, assign(socket, :changeset, changeset) |> assign(:editing, :door)}
  end

  def handle_event("edit_door", %{"id" => id}, socket) do
    door = Map.get_door!(id)
    changeset = Map.change_door(door)
    {:noreply, assign(socket, :changeset, changeset) |> assign(:editing, :door)}
  end

  def handle_event("delete_door", %{"id" => id}, socket) do
    door = Map.get_door!(id)
    {:ok, _} = Map.delete_door(door)
    
    rooms = Map.list_rooms()
    doors = Map.list_doors()
    
    {:noreply,
     socket
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> put_flash(:info, "Door deleted successfully")}
  end

  def handle_event("validate_door", %{"door" => door_params}, socket) do
    changeset = 
      if socket.assigns.editing == :door && socket.assigns.changeset.data.id do
        Map.change_door(socket.assigns.changeset.data, door_params)
      else
        Map.change_door(%Door{}, door_params)
      end
      |> Map.put(:action, :validate)
    
    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save_door", %{"door" => door_params}, socket) do
    case save_door(socket, door_params) do
      {:ok, socket} -> {:noreply, socket}
      {:error, socket} -> {:noreply, socket}
    end
  end

  def handle_event("cancel_door", _params, socket) do
    {:noreply, assign(socket, :editing, nil) |> assign(:changeset, nil)}
  end

  # Map interaction events
  def handle_event("zoom_in", _params, socket) do
    {:noreply, assign(socket, :zoom, min(socket.assigns.zoom * 1.2, 5.0))}
  end

  def handle_event("zoom_out", _params, socket) do
    {:noreply, assign(socket, :zoom, max(socket.assigns.zoom / 1.2, 0.2))}
  end

  def handle_event("reset_view", _params, socket) do
    {:noreply, 
     socket
     |> assign(:zoom, 1.0)
     |> assign(:pan_x, 0)
     |> assign(:pan_y, 0)}
  end

  def handle_event("mousedown", %{"clientX" => x, "clientY" => y}, socket) do
    {:noreply, assign(socket, :drag_start, %{x: x, y: y})}
  end

  def handle_event("mousemove", %{"clientX" => x, "clientY" => y}, socket) do
    case socket.assigns.drag_start do
      nil -> {:noreply, socket}
      start ->
        delta_x = x - start.x
        delta_y = y - start.y
        {:noreply, 
         socket
         |> assign(:pan_x, socket.assigns.pan_x + delta_x)
         |> assign(:pan_y, socket.assigns.pan_y + delta_y)
         |> assign(:drag_start, %{x: x, y: y})}
    end
  end

  def handle_event("mouseup", _params, socket) do
    {:noreply, assign(socket, :drag_start, nil)}
  end

  def handle_event("mouseleave", _params, socket) do
    {:noreply, assign(socket, :drag_start, nil)}
  end

  # Generate default map
  def handle_event("generate_default_map", _params, socket) do
    # Clear existing rooms and doors first
    Shard.Repo.delete_all(Door)
    Shard.Repo.delete_all(Room)
    
    # Create a 3x3 grid of rooms
    rooms = 
      for x <- 0..2, y <- 0..2 do
        name = "Room #{x},#{y}"
        description = "A room in the default map at coordinates (#{x}, #{y})"
        room_type = if x == 1 and y == 1, do: "safe_zone", else: "standard"
        
        {:ok, room} = Map.create_room(%{
          name: name,
          description: description,
          x_coordinate: x,
          y_coordinate: y,
          z_coordinate: 0,
          room_type: room_type,
          is_public: true
        })
        
        room
      end
    
    # Create doors between adjacent rooms
    for x <- 0..2, y <- 0..2 do
      current_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y))
      
      # Connect to room to the east
      if x < 2 do
        east_room = Enum.find(rooms, &(&1.x_coordinate == x + 1 && &1.y_coordinate == y))
        Map.create_door(%{
          from_room_id: current_room.id,
          to_room_id: east_room.id,
          direction: "east",
          door_type: "standard",
          is_locked: false
        })
      end
      
      # Connect to room to the south
      if y < 2 do
        south_room = Enum.find(rooms, &(&1.x_coordinate == x && &1.y_coordinate == y + 1))
        Map.create_door(%{
          from_room_id: current_room.id,
          to_room_id: south_room.id,
          direction: "south",
          door_type: "standard",
          is_locked: false
        })
      end
    end

    # Refresh the rooms and doors lists
    rooms = Map.list_rooms()
    doors = Map.list_doors()
    
    {:noreply,
     socket
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> put_flash(:info, "Default 3x3 map generated successfully!")}
  end

  defp save_room(socket, room_params) do
    case socket.assigns.editing do
      :room when not is_nil(socket.assigns.changeset) and not is_nil(socket.assigns.changeset.data.id) ->
        # Update existing room
        case Map.update_room(socket.assigns.changeset.data, room_params) do
          {:ok, _room} ->
            rooms = Map.list_rooms()
            {:ok, assign(socket, :rooms, rooms) |> assign(:editing, nil) |> assign(:changeset, nil)
                  |> put_flash(:info, "Room updated successfully")}
          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end
      _ ->
        # Create new room
        case Map.create_room(room_params) do
          {:ok, _room} ->
            rooms = Map.list_rooms()
            {:ok, assign(socket, :rooms, rooms) |> assign(:editing, nil) |> assign(:changeset, nil)
                  |> put_flash(:info, "Room created successfully")}
          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end
    end
  end

  defp save_door(socket, door_params) do
    case socket.assigns.editing do
      :door when not is_nil(socket.assigns.changeset) and not is_nil(socket.assigns.changeset.data.id) ->
        # Update existing door
        case Map.update_door(socket.assigns.changeset.data, door_params) do
          {:ok, _door} ->
            doors = Map.list_doors()
            {:ok, assign(socket, :doors, doors) |> assign(:editing, nil) |> assign(:changeset, nil)
                  |> put_flash(:info, "Door updated successfully")}
          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end
      _ ->
        # Create new door
        case Map.create_door(door_params) do
          {:ok, _door} ->
            doors = Map.list_doors()
            {:ok, assign(socket, :doors, doors) |> assign(:editing, nil) |> assign(:changeset, nil)
                  |> put_flash(:info, "Door created successfully")}
          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Map Management
      <:subtitle>View and manage the game map</:subtitle>
    </.header>

    <div class="mt-8">
      <div class="flex justify-between items-center mb-4">
        <div class="tabs tabs-lifted">
          <button 
            type="button" 
            class={["tab", @tab == "rooms" && "tab-active"]}
            phx-click="change_tab" 
            phx-value-tab="rooms"
          >
            Rooms
          </button>
          <button 
            type="button" 
            class={["tab", @tab == "doors" && "tab-active"]}
            phx-click="change_tab" 
            phx-value-tab="doors"
          >
            Doors
          </button>
          <button 
            type="button" 
            class={["tab", @tab == "map" && "tab-active"]}
            phx-click="change_tab" 
            phx-value-tab="map"
          >
            Map Visualization
          </button>
        </div>
        
        <button 
          type="button" 
          class="btn btn-secondary"
          phx-click="generate_default_map"
        >
          Generate Default Map
        </button>
      </div>

      <div class="mt-6">
        <%= case @tab do %>
          <% "rooms" -> %>
            <.rooms_tab rooms={@rooms} />
          <% "doors" -> %>
            <.doors_tab doors={@doors} rooms={@rooms} />
          <% "map" -> %>
            <.map_visualization 
              rooms={@rooms} 
              doors={@doors} 
              zoom={@zoom} 
              pan_x={@pan_x} 
              pan_y={@pan_y} 
            />
        <% end %>
      </div>
    </div>

    <!-- Room Form Modal -->
    <.modal :if={@editing == :room} id="room-modal" show>
      <.header>
        <%= if @changeset.data.id, do: "Edit Room", else: "New Room" %>
        <:subtitle>Manage room details</:subtitle>
      </.header>
      
      <.simple_form
        for={@changeset}
        id="room-form"
        phx-change="validate_room"
        phx-submit="save_room"
      >
        <.input field={@changeset[:name]} type="text" label="Name" required />
        <.input field={@changeset[:description]} type="textarea" label="Description" />
        <div class="grid grid-cols-3 gap-4">
          <.input field={@changeset[:x_coordinate]} type="number" label="X" />
          <.input field={@changeset[:y_coordinate]} type="number" label="Y" />
          <.input field={@changeset[:z_coordinate]} type="number" label="Z" />
        </div>
        <.input field={@changeset[:room_type]} type="select" label="Type" prompt="Choose a type" options={[
          {"Standard", "standard"},
          {"Safe Zone", "safe_zone"},
          {"Shop", "shop"},
          {"Dungeon", "dungeon"},
          {"Treasure Room", "treasure_room"},
          {"Trap Room", "trap_room"}
        ]} />
        <.input field={@changeset[:is_public]} type="checkbox" label="Public Room" />
        
        <:actions>
          <.button phx-click="cancel_room" kind="secondary">Cancel</.button>
          <.button phx-disable-with="Saving...">Save Room</.button>
        </:actions>
      </.simple_form>
    </.modal>

    <!-- Door Form Modal -->
    <.modal :if={@editing == :door} id="door-modal" show>
      <.header>
        <%= if @changeset.data.id, do: "Edit Door", else: "New Door" %>
        <:subtitle>Manage door details</:subtitle>
      </.header>
      
      <.simple_form
        for={@changeset}
        id="door-form"
        phx-change="validate_door"
        phx-submit="save_door"
      >
        <.input field={@changeset[:from_room_id]} type="select" label="From Room" prompt="Select room" options={
          Enum.map(@rooms, &{&1.name, &1.id})
        } required />
        <.input field={@changeset[:to_room_id]} type="select" label="To Room" prompt="Select room" options={
          Enum.map(@rooms, &{&1.name, &1.id})
        } required />
        <.input field={@changeset[:direction]} type="select" label="Direction" prompt="Select direction" options={[
          {"North", "north"},
          {"South", "south"},
          {"East", "east"},
          {"West", "west"},
          {"Up", "up"},
          {"Down", "down"},
          {"Northeast", "northeast"},
          {"Northwest", "northwest"},
          {"Southeast", "southeast"},
          {"Southwest", "southwest"}
        ]} required />
        <.input field={@changeset[:door_type]} type="select" label="Type" prompt="Choose a type" options={[
          {"Standard", "standard"},
          {"Gate", "gate"},
          {"Portal", "portal"},
          {"Secret", "secret"},
          {"Locked Gate", "locked_gate"}
        ]} />
        <.input field={@changeset[:is_locked]} type="checkbox" label="Locked" />
        <.input field={@changeset[:key_required]} type="text" label="Key Required" />
        
        <:actions>
          <.button phx-click="cancel_door" kind="secondary">Cancel</.button>
          <.button phx-disable-with="Saving...">Save Door</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  defp rooms_tab(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <div class="mb-4">
        <.button phx-click="new_room" class="btn btn-primary">New Room</.button>
      </div>
      
      <%= if Enum.empty?(@rooms) do %>
        <div class="text-center py-8">
          <p class="text-gray-500">No rooms found.</p>
        </div>
      <% else %>
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>Name</th>
              <th>Coordinates</th>
              <th>Type</th>
              <th>Public</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for room <- @rooms do %>
              <tr>
                <td><%= room.name %></td>
                <td>(<%= room.x_coordinate %>, <%= room.y_coordinate %>, <%= room.z_coordinate %>)</td>
                <td><%= room.room_type %></td>
                <td><%= if room.is_public, do: "Yes", else: "No" %></td>
                <td class="flex space-x-2">
                  <.button phx-click="edit_room" phx-value-id={room.id} class="btn btn-sm btn-primary">Edit</.button>
                  <.button phx-click="delete_room" phx-value-id={room.id} class="btn btn-sm btn-error" data-confirm="Are you sure?">Delete</.button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp doors_tab(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <div class="mb-4">
        <.button phx-click="new_door" class="btn btn-primary">New Door</.button>
      </div>
      
      <%= if Enum.empty?(@doors) do %>
        <div class="text-center py-8">
          <p class="text-gray-500">No doors found.</p>
        </div>
      <% else %>
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>From Room</th>
              <th>To Room</th>
              <th>Direction</th>
              <th>Type</th>
              <th>Locked</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for door <- @doors do %>
              <% from_room = Enum.find(@rooms, &(&1.id == door.from_room_id)) %>
              <% to_room = Enum.find(@rooms, &(&1.id == door.to_room_id)) %>
              <tr>
                <td><%= if from_room, do: from_room.name, else: "Unknown" %></td>
                <td><%= if to_room, do: to_room.name, else: "Unknown" %></td>
                <td><%= door.direction %></td>
                <td><%= door.door_type %></td>
                <td><%= if door.is_locked, do: "Yes", else: "No" %></td>
                <td class="flex space-x-2">
                  <.button phx-click="edit_door" phx-value-id={door.id} class="btn btn-sm btn-primary">Edit</.button>
                  <.button phx-click="delete_door" phx-value-id={door.id} class="btn btn-sm btn-error" data-confirm="Are you sure?">Delete</.button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      <% end %>
    </div>
    """
  end

  defp map_visualization(assigns) do
    ~H"""
    <div class="bg-base-200 p-6 rounded-lg">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-xl font-bold">Map Visualization</h3>
        <div class="flex space-x-2">
          <.button phx-click="zoom_in" class="btn btn-sm">Zoom In</.button>
          <.button phx-click="zoom_out" class="btn btn-sm">Zoom Out</.button>
          <.button phx-click="reset_view" class="btn btn-sm">Reset View</.button>
        </div>
      </div>
      
      <%= if Enum.empty?(@rooms) do %>
        <div class="text-center py-8">
          <p class="text-gray-500">No rooms available to display.</p>
        </div>
      <% else %>
        <div 
          class="relative overflow-hidden border border-base-300 rounded bg-white"
          style="height: 600px;"
          phx-hook="MapVisualization"
          id="map-container"
          phx-click="mousedown"
          phx-window-keyup={JS.dispatch("mouseup", to: "#map-container")}
          phx-window-mousemove={JS.dispatch("mousemove", to: "#map-container")}
          phx-mouseup="mouseup"
          phx-mouseleave="mouseleave"
        >
          <svg 
            class="absolute top-0 left-0 w-full h-full"
            style={"transform: scale(#{@zoom}) translate(#{@pan_x}px, #{@pan_y}px); transform-origin: 0 0;"}
          >
            <!-- Render connections between rooms (doors) -->
            <%= for door <- @doors do %>
              <% from_room = Enum.find(@rooms, &(&1.id == door.from_room_id)) %>
              <% to_room = Enum.find(@rooms, &(&1.id == door.to_room_id)) %>
              <%= if from_room && to_room do %>
                <line 
                  x1={50 + from_room.x_coordinate * 100} 
                  y1={50 + from_room.y_coordinate * 100} 
                  x2={50 + to_room.x_coordinate * 100} 
                  y2={50 + to_room.y_coordinate * 100} 
                  stroke="#94a3b8" 
                  stroke-width="2" 
                />
              <% end %>
            <% end %>
            
            <!-- Render rooms as squares -->
            <%= for room <- @rooms do %>
              <rect 
                x={25 + room.x_coordinate * 100} 
                y={25 + room.y_coordinate * 100} 
                width="50" 
                height="50" 
                fill={room_color(room)} 
                stroke="#1e293b" 
                stroke-width="2" 
                rx="5"
              />
              <text 
                x={50 + room.x_coordinate * 100} 
                y={55 + room.y_coordinate * 100} 
                text-anchor="middle" 
                font-size="10" 
                fill="#1e293b"
                pointer-events="none"
              >
                <%= room.name %>
              </text>
            <% end %>
          </svg>
        </div>
        
        <div class="mt-4 text-sm text-gray-600">
          <p>Zoom: <%= Float.round(@zoom, 2) %>x | Pan: (<%= @pan_x %>, <%= @pan_y %>)</p>
          <p class="mt-2">Rooms: <%= Enum.count(@rooms) %> | Doors: <%= Enum.count(@doors) %></p>
        </div>
      <% end %>
    </div>
    """
  end

  defp room_color(room) do
    case room.room_type do
      "safe_zone" -> "#bbf7d0"  # green
      "shop" -> "#bfdbfe"       # blue
      "dungeon" -> "#fecaca"    # red
      "treasure_room" -> "#fde68a" # yellow
      "trap_room" -> "#fda4af"  # pink
      _ -> "#e2e8f0"            # gray (default)
    end
  end
end
