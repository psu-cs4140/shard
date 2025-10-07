defmodule ShardWeb.AdminLive.Map do
  @moduledoc """
  Main LiveView for map management.
  Delegates event handling to MapHandlers and imports UI components from MapComponents.
  """
  use ShardWeb, :live_view

  alias Shard.Map
  alias ShardWeb.AdminLive.{MapHandlers, MapComponents}
  import MapComponents

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
     |> assign(:viewing, nil)
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
          <button
            :if={@tab == "room_details"}
            type="button"
            class={["tab", @tab == "room_details" && "tab-active"]}
          >
            Room Details
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
          <% "room_details" -> %>
            <.room_details_tab
              room={@viewing}
              doors_from={@doors_from}
              doors_to={@doors_to}
              changeset={@changeset}
            />
        <% end %>
      </div>
    </div>

    <.modal :if={@editing == :room} id="room-modal" show>
      <.header>
        {if @changeset && @changeset.data.id, do: "Edit Room", else: "New Room"}
        <:subtitle>Manage room details</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="room-form"
        phx-change="validate_room"
        phx-submit="save_room"
      >
        <.input field={f[:name]} type="text" label="Name" required />
        <.input field={f[:description]} type="textarea" label="Description" />
        <div class="grid grid-cols-3 gap-4">
          <.input field={f[:x_coordinate]} type="number" label="X" />
          <.input field={f[:y_coordinate]} type="number" label="Y" />
          <.input field={f[:z_coordinate]} type="number" label="Z" />
        </div>
        <.input
          field={f[:room_type]}
          type="select"
          label="Type"
          prompt="Choose a type"
          options={[
            {"Standard", "standard"},
            {"Safe Zone", "safe_zone"},
            {"Shop", "shop"},
            {"Dungeon", "dungeon"},
            {"Treasure Room", "treasure_room"},
            {"Trap Room", "trap_room"}
          ]}
        />
        <.input field={f[:is_public]} type="checkbox" label="Public Room" />

        <:actions>
          <.button phx-click="cancel_room" variant="secondary">Cancel</.button>
          <.button phx-disable-with="Saving...">Save Room</.button>
        </:actions>
      </.simple_form>
    </.modal>

    <.modal :if={@editing == :door} id="door-modal" show>
      <.header>
        {if @changeset && @changeset.data.id, do: "Edit Door", else: "New Door"}
        <:subtitle>Manage door details</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="door-form"
        phx-change="validate_door"
        phx-submit="save_door"
      >
        <.input
          field={f[:from_room_id]}
          type="select"
          label="From Room"
          prompt="Select room"
          options={Enum.map(@rooms, &{&1.name, &1.id})}
          required
        />
        <.input
          field={f[:to_room_id]}
          type="select"
          label="To Room"
          prompt="Select room"
          options={Enum.map(@rooms, &{&1.name, &1.id})}
          required
        />
        <.input
          field={f[:direction]}
          type="select"
          label="Direction"
          prompt="Select direction"
          options={[
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
          ]}
          required
        />
        <.input
          field={f[:door_type]}
          type="select"
          label="Type"
          prompt="Choose a type"
          options={[
            {"Standard", "standard"},
            {"Gate", "gate"},
            {"Portal", "portal"},
            {"Secret", "secret"},
            {"Locked Gate", "locked_gate"}
          ]}
        />
        <.input field={f[:is_locked]} type="checkbox" label="Locked" />
        <.input field={f[:key_required]} type="text" label="Key Required" />

        <:actions>
          <.button phx-click="cancel_door" variant="secondary">Cancel</.button>
          <.button phx-disable-with="Saving...">Save Door</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  # Event handler delegations
  @impl true
  def handle_event("change_tab", params, socket), do: MapHandlers.handle_change_tab(params, socket)

  # Room events
  def handle_event("new_room", params, socket), do: MapHandlers.handle_new_room(params, socket)
  def handle_event("edit_room", params, socket), do: MapHandlers.handle_edit_room(params, socket)
  def handle_event("view_room", params, socket), do: MapHandlers.handle_view_room(params, socket)
  def handle_event("delete_room", params, socket), do: MapHandlers.handle_delete_room(params, socket)
  def handle_event("validate_room", params, socket), do: MapHandlers.handle_validate_room(params, socket)
  def handle_event("save_room", params, socket), do: MapHandlers.handle_save_room(params, socket)
  def handle_event("apply_and_save", params, socket), do: MapHandlers.handle_apply_and_save(params, socket)
  def handle_event("generate_description", params, socket), do: MapHandlers.handle_generate_description(params, socket)
  def handle_event("cancel_room", params, socket), do: MapHandlers.handle_cancel_room(params, socket)
  def handle_event("back_to_rooms", params, socket), do: MapHandlers.handle_back_to_rooms(params, socket)

  # Door events
  def handle_event("new_door", params, socket), do: MapHandlers.handle_new_door(params, socket)
  def handle_event("edit_door", params, socket), do: MapHandlers.handle_edit_door(params, socket)
  def handle_event("delete_door", params, socket), do: MapHandlers.handle_delete_door(params, socket)
  def handle_event("validate_door", params, socket), do: MapHandlers.handle_validate_door(params, socket)
  def handle_event("save_door", params, socket), do: MapHandlers.handle_save_door(params, socket)
  def handle_event("cancel_door", params, socket), do: MapHandlers.handle_cancel_door(params, socket)

  # Map interaction events
  def handle_event("zoom_in", params, socket), do: MapHandlers.handle_zoom_in(params, socket)
  def handle_event("zoom_out", params, socket), do: MapHandlers.handle_zoom_out(params, socket)
  def handle_event("reset_view", params, socket), do: MapHandlers.handle_reset_view(params, socket)
  def handle_event("mousedown", params, socket), do: MapHandlers.handle_mousedown(params, socket)
  def handle_event("mousemove", params, socket), do: MapHandlers.handle_mousemove(params, socket)
  def handle_event("mouseup", params, socket), do: MapHandlers.handle_mouseup(params, socket)
  def handle_event("mouseleave", params, socket), do: MapHandlers.handle_mouseleave(params, socket)

  # Generate default map
  def handle_event("generate_default_map", params, socket), do: MapHandlers.handle_generate_default_map(params, socket)
end
