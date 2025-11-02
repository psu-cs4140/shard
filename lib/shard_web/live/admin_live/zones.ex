defmodule ShardWeb.AdminLive.Zones do
  @moduledoc """
  LiveView for zone management in the admin panel.
  """
  use ShardWeb, :live_view

  alias Shard.Map
  alias Shard.Map.Zone

  @impl true
  def mount(_params, _session, socket) do
    zones = Map.list_zones()

    {:ok,
     socket
     |> assign(:zones, zones)
     |> assign(:page_title, "Zone Management")
     |> assign(:editing, nil)
     |> assign(:changeset, nil)
     |> assign(:selected_zone, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      Zone Management
      <:subtitle>Create and manage zones (maps) for your game world</:subtitle>
      <:actions>
        <.button phx-click="new_zone">
          <.icon name="hero-plus" class="w-4 h-4 mr-1" /> Create Zone
        </.button>
      </:actions>
    </.header>

    <div class="mt-8">
      <div class="grid grid-cols-1 gap-4">
        <%= for zone <- @zones do %>
          <div class="card bg-base-200 shadow-xl">
            <div class="card-body">
              <div class="flex justify-between items-start">
                <div class="flex-1">
                  <h2 class="card-title">
                    {zone.name}
                    <div class={[
                      "badge",
                      (zone.is_active && "badge-success") || "badge-error"
                    ]}>
                      {if zone.is_active, do: "Active", else: "Inactive"}
                    </div>
                    <div class="badge badge-info">{zone.zone_type}</div>
                  </h2>
                  <p class="text-sm opacity-70 mt-2">{zone.description}</p>
                  <div class="mt-3 flex gap-3 text-sm">
                    <span>
                      <strong>Slug:</strong>
                      {zone.slug}
                    </span>
                    <span>
                      <strong>Level Range:</strong>
                      {zone.min_level}-{zone.max_level || "∞"}
                    </span>
                    <span>
                      <strong>Rooms:</strong>
                      {length(Map.list_rooms_by_zone(zone.id))}
                    </span>
                  </div>
                </div>
                <div class="flex gap-2">
                  <.link
                    navigate={~p"/admin/map?zone_id=#{zone.id}"}
                    class="btn btn-sm btn-primary"
                  >
                    <.icon name="hero-map" class="w-4 h-4" /> Manage Map
                  </.link>
                  <.button
                    phx-click="edit_zone"
                    phx-value-id={zone.id}
                    class="btn-sm"
                    variant="secondary"
                  >
                    <.icon name="hero-pencil" class="w-4 h-4" />
                  </.button>
                  <.button
                    phx-click="delete_zone"
                    phx-value-id={zone.id}
                    class="btn-sm btn-error"
                    data-confirm="Are you sure you want to delete this zone? All rooms and doors within it will also be deleted."
                  >
                    <.icon name="hero-trash" class="w-4 h-4" />
                  </.button>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>

    <.modal :if={@editing} id="zone-modal" show on_cancel={JS.push("cancel_zone")}>
      <.header>
        {if @changeset.data.id, do: "Edit Zone", else: "New Zone"}
        <:subtitle>Configure zone details</:subtitle>
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="zone-form"
        phx-change="validate_zone"
        phx-submit="save_zone"
      >
        <.input field={f[:name]} type="text" label="Name" required />
        <.input
          field={f[:slug]}
          type="text"
          label="Slug"
          placeholder="vampire-castle"
          required
          help="URL-friendly identifier (lowercase letters, numbers, hyphens)"
        />
        <.input field={f[:description]} type="textarea" label="Description" rows="3" />

        <.input
          field={f[:zone_type]}
          type="select"
          label="Zone Type"
          prompt="Choose a type"
          options={[
            {"Standard", "standard"},
            {"Dungeon", "dungeon"},
            {"Town", "town"},
            {"Wilderness", "wilderness"},
            {"Raid", "raid"},
            {"PvP Area", "pvp"},
            {"Safe Zone", "safe_zone"}
          ]}
        />

        <div class="grid grid-cols-2 gap-4">
          <.input
            field={f[:min_level]}
            type="number"
            label="Min Level"
            min="1"
            value={f[:min_level].value || 1}
          />
          <.input
            field={f[:max_level]}
            type="number"
            label="Max Level"
            min="1"
            placeholder="Leave empty for no limit"
          />
        </div>

        <div class="grid grid-cols-2 gap-4">
          <.input field={f[:display_order]} type="number" label="Display Order" value="0" />
          <.input field={f[:is_public]} type="checkbox" label="Public Access" />
        </div>

        <.input field={f[:is_active]} type="checkbox" label="Active" />

        <:actions>
          <.button phx-click="cancel_zone" type="button" variant="secondary">Cancel</.button>
          <.button phx-disable-with="Saving...">Save Zone</.button>
        </:actions>
      </.simple_form>
    </.modal>
    """
  end

  @impl true
  def handle_event("new_zone", _params, socket) do
    changeset = Map.change_zone(%Zone{})

    {:noreply,
     socket
     |> assign(:editing, :new)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("edit_zone", %{"id" => id}, socket) do
    zone = Map.get_zone!(id)
    changeset = Map.change_zone(zone)

    {:noreply,
     socket
     |> assign(:editing, :edit)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate_zone", %{"zone" => zone_params}, socket) do
    changeset =
      (socket.assigns.changeset.data || %Zone{})
      |> Map.change_zone(zone_params)

    changeset = Elixir.Map.put(changeset, :action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  @impl true
  def handle_event("save_zone", %{"zone" => zone_params}, socket) do
    case socket.assigns.editing do
      :new ->
        case Map.create_zone(zone_params) do
          {:ok, _zone} ->
            {:noreply,
             socket
             |> put_flash(:info, "Zone created successfully")
             |> assign(:editing, nil)
             |> assign(:changeset, nil)
             |> assign(:zones, Map.list_zones())}

          {:error, changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end

      :edit ->
        zone = socket.assigns.changeset.data

        case Map.update_zone(zone, zone_params) do
          {:ok, _zone} ->
            {:noreply,
             socket
             |> put_flash(:info, "Zone updated successfully")
             |> assign(:editing, nil)
             |> assign(:changeset, nil)
             |> assign(:zones, Map.list_zones())}

          {:error, changeset} ->
            {:noreply, assign(socket, :changeset, changeset)}
        end
    end
  end

  @impl true
  def handle_event("cancel_zone", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing, nil)
     |> assign(:changeset, nil)}
  end

  @impl true
  def handle_event("delete_zone", %{"id" => id}, socket) do
    zone = Map.get_zone!(id)

    case Map.delete_zone(zone) do
      {:ok, _zone} ->
        {:noreply,
         socket
         |> put_flash(:info, "Zone deleted successfully")
         |> assign(:zones, Map.list_zones())}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete zone")}
    end
  end
end
