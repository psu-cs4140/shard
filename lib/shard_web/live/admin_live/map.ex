defmodule ShardWeb.AdminLive.Map do
  use ShardWeb, :live_view

  alias Shard.Map

  @impl true
  def mount(_params, _session, socket) do
    rooms = Map.list_rooms()
    doors = Map.list_doors()
    
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
                <td><%= if door.from_room, do: door.from_room.name, else: "Unknown" %></td>
                <td><%= if door.to_room, do: door.to_room.name, else: "Unknown" %></td>
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
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          <%= for room <- Enum.take(@rooms, 9) do %>
            <div class="card bg-base-100 shadow">
              <div class="card-body p-4">
                <h4 class="card-title text-sm"><%= room.name %></h4>
                <div class="text-xs">
                  <p>Type: <%= room.room_type %></p>
                  <p>Coords: (<%= room.x_coordinate %>, <%= room.y_coordinate %>)</p>
                  <%= if room.description do %>
                    <p class="mt-1 text-xs"><%= String.slice(room.description || "", 0, 50) <> if String.length(room.description || "") > 50, do: "..." %></p>
                  <% end %>
                </div>
                <div class="card-actions justify-end mt-2">
                  <button class="btn btn-xs" disabled>View</button>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        
        <div class="mt-6 text-center">
          <p class="text-sm">Showing <%= min(9, length(@rooms)) %> of <%= length(@rooms) %> rooms</p>
          <p class="text-xs text-base-content/70 mt-2">In a full implementation, this would show connections between rooms</p>
        </div>
      <% end %>
    </div>
    """
  end
end
