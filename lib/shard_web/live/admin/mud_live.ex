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
            <.input field={