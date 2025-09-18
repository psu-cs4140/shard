defmodule ShardWeb.AdminLive.Map do
  use ShardWeb, :live_view

  alias Shard.Map

  @impl true
  def mount(_params, _session, socket) do
    rooms = Map.list_rooms()
    # Preload door associations to avoid N+1 queries
    doors = Map.list_doors() |> Enum.map(&Map.Repo.preload(&1, [:from_room, :to_room]))
    
    {:ok,
     socket
     |> assign(:rooms, rooms)
     |> assign(:doors, doors)
     |> assign(:page_title, "Map Management")
     |> assign(:tab, "rooms")}
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

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Map Management
      <:subtitle>View and manage the game map</:subtitle>
    </.header>

    <div class="mt-8">
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
        <button 
          type="button" 
          class={["tab", @tab == "editor" && "tab-active"]}
          phx-click="change_tab" 
          phx-value-tab="editor"
        >
          Map Editor
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
          <% "editor" -> %>
            <.map_editor rooms={@rooms} doors={@doors} />
        <% end %>
      </div>
    </div>
    """
  end

  defp rooms_tab(assigns) do
    ~H"""
    <div class="overflow-x-auto">
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
          <!-- Simple grid-based map visualization -->
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

  defp map_editor(assigns) do
    ~H"""
    <div class="bg-base-200 p-6 rounded-box">
      <div class="text-center mb-4">
        <h3 class="text-lg font-bold">Map Editor</h3>
        <p class="text-sm text-base-content/70">Create and edit rooms and connections</p>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h4 class="card-title">Create New Room</h4>
            <form phx-submit="create-room" class="space-y-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Room Name</span>
                </label>
                <input type="text" name="room[name]" placeholder="Room Name" class="input input-bordered" required />
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Description</span>
                </label>
                <textarea name="room[description]" placeholder="Room Description" class="textarea textarea-bordered"></textarea>
              </div>
              
              <div class="grid grid-cols-2 gap-4">
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">X Coordinate</span>
                  </label>
                  <input type="number" name="room[x_coordinate]" value="0" class="input input-bordered" />
                </div>
                
                <div class="form-control">
                  <label class="label">
                    <span class="label-text">Y Coordinate</span>
                  </label>
                  <input type="number" name="room[y_coordinate]" value="0" class="input input-bordered" />
                </div>
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Room Type</span>
                </label>
                <select name="room[room_type]" class="select select-bordered">
                  <option value="standard">Standard</option>
                  <option value="safe_zone">Safe Zone</option>
                  <option value="shop">Shop</option>
                  <option value="dungeon">Dungeon</option>
                  <option value="treasure_room">Treasure Room</option>
                  <option value="trap_room">Trap Room</option>
                </select>
              </div>
              
              <div class="form-control">
                <label class="label cursor-pointer">
                  <span class="label-text">Public Room</span>
                  <input type="checkbox" name="room[is_public]" class="checkbox" checked />
                </label>
              </div>
              
              <div class="card-actions justify-end">
                <button type="submit" class="btn btn-primary">Create Room</button>
              </div>
            </form>
          </div>
        </div>
        
        <div class="card bg-base-100 shadow">
          <div class="card-body">
            <h4 class="card-title">Create New Door</h4>
            <form phx-submit="create-door" class="space-y-4">
              <div class="form-control">
                <label class="label">
                  <span class="label-text">From Room</span>
                </label>
                <select name="door[from_room_id]" class="select select-bordered" required>
                  <option disabled selected>Select a room</option>
                  <%= for room <- @rooms do %>
                    <option value={room.id}><%= room.name %></option>
                  <% end %>
                </select>
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">To Room</span>
                </label>
                <select name="door[to_room_id]" class="select select-bordered" required>
                  <option disabled selected>Select a room</option>
                  <%= for room <- @rooms do %>
                    <option value={room.id}><%= room.name %></option>
                  <% end %>
                </select>
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Direction</span>
                </label>
                <select name="door[direction]" class="select select-bordered" required>
                  <option value="north">North</option>
                  <option value="south">South</option>
                  <option value="east">East</option>
                  <option value="west">West</option>
                  <option value="up">Up</option>
                  <option value="down">Down</option>
                  <option value="northeast">Northeast</option>
                  <option value="northwest">Northwest</option>
                  <option value="southeast">Southeast</option>
                  <option value="southwest">Southwest</option>
                </select>
              </div>
              
              <div class="form-control">
                <label class="label">
                  <span class="label-text">Door Type</span>
                </label>
                <select name="door[door_type]" class="select select-bordered">
                  <option value="standard">Standard</option>
                  <option value="gate">Gate</option>
                  <option value="portal">Portal</option>
                  <option value="secret">Secret</option>
                  <option value="locked_gate">Locked Gate</option>
                </select>
              </div>
              
              <div class="form-control">
                <label class="label cursor-pointer">
                  <span class="label-text">Locked</span>
                  <input type="checkbox" name="door[is_locked]" class="checkbox" />
                </label>
              </div>
              
              <div class="card-actions justify-end">
                <button type="submit" class="btn btn-primary">Create Door</button>
              </div>
            </form>
          </div>
        </div>
      </div>
      
      <div class="mt-8">
        <h4 class="font-bold mb-4">Existing Map Elements</h4>
        
        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h5 class="card-title">Rooms (<%= length(@rooms) %>)</h5>
              <div class="max-h-60 overflow-y-auto">
                <%= if Enum.empty?(@rooms) do %>
                  <p class="text-gray-500 text-sm">No rooms available</p>
                <% else %>
                  <ul class="space-y-2">
                    <%= for room <- @rooms do %>
                      <li class="flex justify-between items-center p-2 hover:bg-base-200 rounded">
                        <span><%= room.name %></span>
                        <span class="text-xs text-gray-500">(<%= room.x_coordinate %>, <%= room.y_coordinate %>)</span>
                      </li>
                    <% end %>
                  </ul>
                <% end %>
              </div>
            </div>
          </div>
          
          <div class="card bg-base-100 shadow">
            <div class="card-body">
              <h5 class="card-title">Doors (<%= length(@doors) %>)</h5>
              <div class="max-h-60 overflow-y-auto">
                <%= if Enum.empty?(@doors) do %>
                  <p class="text-gray-500 text-sm">No doors available</p>
                <% else %>
                  <ul class="space-y-2">
                    <%= for door <- @doors do %>
                      <li class="flex justify-between items-center p-2 hover:bg-base-200 rounded">
                        <span>
                          <%= if door.from_room, do: door.from_room.name, else: "Room #{door.from_room_id}" %> 
                          → 
                          <%= if door.to_room, do: door.to_room.name, else: "Room #{door.to_room_id}" %>
                        </span>
                        <span class="text-xs text-gray-500"><%= door.direction %></span>
                      </li>
                    <% end %>
                  </ul>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
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
