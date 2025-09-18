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
     |> assign(:editing, nil)}
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
    {:noreply, assign(socket, :changeset, changeset, :editing, :room)}
  end

  def handle_event("edit_room", %{"id" => id}, socket) do
    room = Map.get_room!(id)
    changeset = Map.change_room(room)
    {:noreply, assign(socket, :changeset, changeset, :editing, :room)}
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
    {:noreply, assign(socket, :editing, nil, :changeset, nil)}
  end

  # Door events
  def handle_event("new_door", _params, socket) do
    changeset = Map.change_door(%Door{})
    {:noreply, assign(socket, :changeset, changeset, :editing, :door)}
  end

  def handle_event("edit_door", %{"id" => id}, socket) do
    door = Map.get_door!(id)
    changeset = Map.change_door(door)
    {:noreply, assign(socket, :changeset, changeset, :editing, :door)}
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
    {:noreply, assign(socket, :editing, nil, :changeset, nil)}
  end

  defp save_room(socket, room_params) do
    case socket.assigns.editing do
      :room when not is_nil(socket.assigns.changeset) and not is_nil(socket.assigns.changeset.data.id) ->
        # Update existing room
        case Map.update_room(socket.assigns.changeset.data, room_params) do
          {:ok, _room} ->
            rooms = Map.list_rooms()
            {:ok, assign(socket, :rooms, rooms, :editing, nil, :changeset, nil)
                  |> put_flash(:info, "Room updated successfully")}
          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end
      _ ->
        # Create new room
        case Map.create_room(room_params) do
          {:ok, _room} ->
            rooms = Map.list_rooms()
            {:ok, assign(socket, :rooms, rooms, :editing, nil, :changeset, nil)
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
            {:ok, assign(socket, :doors, doors, :editing, nil, :changeset, nil)
                  |> put_flash(:info, "Door updated successfully")}
          {:error, changeset} ->
            {:error, assign(socket, :changeset, changeset)}
        end
      _ ->
        # Create new door
        case Map.create_door(door_params) do
          {:ok, _door} ->
            doors = Map.list_doors()
            {:ok, assign(socket, :doors, doors, :editing, nil, :changeset, nil)
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
            <.doors_tab doors={@doors} />
          <% "map" -> %>
            <.map_visualization rooms={@rooms} doors={@doors} />
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
          <p class="text-gray-500">No rooms found in the database.</p>
        </div>
      <% else %>
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Description</th>
              <th>Coordinates</th>
              <th>Type</th>
              <th>Public</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for room <- @rooms do %>
              <tr>
                <td><%= room.id %></td>
                <td><%= room.name %></td>
                <td><%= if room.description, do: room.description, else: "No description" %></td>
                <td>(<%= room.x_coordinate %>, <%= room.y_coordinate %>, <%= room.z_coordinate %>)</td>
                <td><%= room.room_type %></td>
                <td><%= if room.is_public, do: "Yes", else: "No" %></td>
                <td class="flex gap-2">
                  <.button phx-click="edit_room" phx-value-id={room.id} class="btn btn-sm">Edit</.button>
                  <.link
                    phx-click="delete_room"
                    phx-value-id={room.id}
                    data-confirm="Are you sure you want to delete this room?"
                    class="btn btn-sm btn-error"
                  >
                    Delete
                  </.link>
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
          <p class="text-gray-500">No doors found in the database.</p>
        </div>
      <% else %>
        <table class="table table-zebra">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>From Room</th>
              <th>To Room</th>
              <th>Direction</th>
              <th>Locked</th>
              <th>Type</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for door <- @doors do %>
              <tr>
                <td><%= door.id %></td>
                <td><%= if door.name, do: door.name, else: "Unnamed" %></td>
                <td><%= if door.from_room, do: door.from_room.name, else: "Unknown (ID: #{door.from_room_id})" %></td>
                <td><%= if door.to_room, do: door.to_room.name, else: "Unknown (ID: #{door.to_room_id})" %></td>
                <td><%= door.direction %></td>
                <td><%= if door.is_locked, do: "Yes", else: "No" %></td>
                <td><%= door.door_type %></td>
                <td class="flex gap-2">
                  <.button phx-click="edit_door" phx-value-id={door.id} class="btn btn-sm">Edit</.button>
                  <.link
                    phx-click="delete_door"
                    phx-value-id={door.id}
                    data-confirm="Are you sure you want to delete this door?"
                    class="btn btn-sm btn-error"
                  >
                    Delete
                  </.link>
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
    <div class="bg-base-200 p-6 rounded-box">
      <div class="text-center mb-4">
        <h3 class="text-lg font-bold">Map Visualization</h3>
        <p class="text-sm text-base-content/70">This is a simplified visualization of the game map</p>
      </div>
      
      <%= if Enum.empty?(@rooms) do %>
        <div class="text-center py-8">
          <p class="text-gray-500">No rooms available to display.</p>
        </div>
      <% else %>
        <div class="relative overflow-auto border border-base-300 rounded-box bg-white min-h-[500px]">
          <div class="relative p-4 min-h-full">
            <%= for room <- @rooms do %>
              <div 
                class="absolute w-24 h-24 bg-primary text-primary-content rounded-lg shadow-md flex flex-col items-center justify-center text-xs font-medium border-2 border-primary-content/30"
                style={"left: #{rem(room.x_coordinate, 10) * 120 + 20}px; top: #{div(room.x_coordinate, 10) * 120 + 20}px;"}
              >
                <div class="font-bold truncate w-full px-1 text-center"><%= room.name %></div>
                <div class="text-xs mt-1">(<%= room.x_coordinate %>, <%= room.y_coordinate %>)</div>
              </div>
            <% end %>
            
            <!-- Draw connections between rooms -->
            <%= for door <- @doors do %>
              <%= if door.from_room && door.to_room do %>
                <.connection_line from_room={door.from_room} to_room={door.to_room} direction={door.direction} />
              <% end %>
            <% end %>
          </div>
        </div>
        
        <div class="mt-6">
          <h4 class="font-bold mb-2">Map Legend</h4>
          <div class="flex flex-wrap gap-4">
            <div class="flex items-center">
              <div class="w-4 h-4 bg-primary mr-2"></div>
              <span class="text-sm">Room</span>
            </div>
            <div class="flex items-center">
              <div class="w-8 h-1 bg-secondary mr-2"></div>
              <span class="text-sm">Connection</span>
            </div>
          </div>
        </div>
        
        <div class="mt-4 text-center">
          <p class="text-sm">Showing <%= min(9, length(@rooms)) %> of <%= length(@rooms) %> rooms</p>
          <p class="text-xs text-base-content/70 mt-2">In a full implementation, this would show connections between rooms</p>
        </div>
      <% end %>
    </div>
    """
  end

  defp connection_line(assigns) do
    # Simple line drawing between rooms
    from_x = rem(assigns.from_room.x_coordinate, 10) * 120 + 20 + 12
    from_y = div(assigns.from_room.x_coordinate, 10) * 120 + 20 + 12
    to_x = rem(assigns.to_room.x_coordinate, 10) * 120 + 20 + 12
    to_y = div(assigns.to_room.x_coordinate, 10) * 120 + 20 + 12
    
    assigns = assign(assigns, :from_x, from_x)
    assigns = assign(assigns, :from_y, from_y)
    assigns = assign(assigns, :to_x, to_x)
    assigns = assign(assigns, :to_y, to_y)
    
    ~H"""
    <svg class="absolute top-0 left-0 w-full h-full pointer-events-none">
      <line 
        x1={@from_x} 
        y1={@from_y} 
        x2={@to_x} 
        y2={@to_y} 
        stroke="currentColor" 
        stroke-width="2" 
        class="text-secondary"
        marker-end="url(#arrowhead)"
      />
    </svg>
    """
  end
end
