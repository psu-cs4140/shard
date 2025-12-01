defmodule ShardWeb.ZoneSelectionLive do
  @moduledoc """
  LiveView for players to select which zone/map they want to enter.
  """
  use ShardWeb, :live_view

  alias Shard.{Map, Characters, Users, Achievements}
  alias Shard.Items.AdminStick

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    character_id = params["character_id"]

    character =
      if character_id do
        Characters.get_character!(character_id)
      else
        nil
      end

    zones = Map.list_active_zones()
    # Group zones by name to show zone types, not individual instances
    zone_types = 
      zones
      |> Enum.group_by(& &1.name)
      |> Enum.map(fn {name, zone_instances} ->
        # Use the first instance as the representative for display
        representative = List.first(zone_instances)
        %{
          name: name,
          description: representative.description,
          zone_type: representative.zone_type,
          min_level: representative.min_level,
          max_level: representative.max_level,
          instances: zone_instances,
          room_count: zone_instances |> Enum.map(&length(Map.list_rooms_by_zone(&1.id))) |> Enum.sum()
        }
      end)
      |> Enum.sort_by(& &1.name)

    {:noreply,
     socket
     |> assign(:zone_types, zone_types)
     |> assign(:character, character)
     |> assign(:page_title, "Select Zone")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-4 py-8">
      <.header>
        Select a Zone to Explore
        <:subtitle>
          <%= if @character do %>
            Playing as: {@character.name} (Level {@character.level} {@character.class})
          <% else %>
            Choose a zone to begin your adventure
          <% end %>
        </:subtitle>
      </.header>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mt-8">
        <%= for zone_type <- @zone_types do %>
          <div class="card bg-base-200 shadow-xl hover:shadow-2xl transition-shadow">
            <div class="card-body">
              <h2 class="card-title">
                {zone_type.name}
                <div class={[
                  "badge",
                  get_zone_type_color(zone_type.zone_type)
                ]}>
                  {String.capitalize(zone_type.zone_type)}
                </div>
              </h2>

              <p class="text-sm opacity-80 min-h-[4rem]">{zone_type.description}</p>

              <div class="divider my-2"></div>

              <div class="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span class="font-semibold">Level Range:</span>
                  <br />
                  {zone_type.min_level}-{zone_type.max_level || "∞"}
                </div>
                <div>
                  <span class="font-semibold">Total Rooms:</span>
                  <br />
                  {zone_type.room_count}
                </div>
              </div>

              <div class="mt-2">
                <span class="font-semibold text-sm">Available Instances:</span>
                <div class="flex flex-wrap gap-1 mt-1">
                  <%= for instance <- zone_type.instances do %>
                    <div class="badge badge-outline text-xs">{instance.zone_id}</div>
                  <% end %>
                </div>
              </div>

              <div class="card-actions justify-end mt-4">
                <%= if @character do %>
                  <div class="dropdown dropdown-top dropdown-end">
                    <div tabindex="0" role="button" class="btn btn-primary">
                      Enter Zone
                      <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path>
                      </svg>
                    </div>
                    <ul tabindex="0" class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52">
                      <%= for instance <- zone_type.instances do %>
                        <li>
                          <a phx-click="enter_zone" phx-value-zone-id={instance.id}>
                            {instance.zone_id}
                            <span class="text-xs opacity-60">
                              ({length(Map.list_rooms_by_zone(instance.id))} rooms)
                            </span>
                          </a>
                        </li>
                      <% end %>
                    </ul>
                  </div>
                <% else %>
                  <div class="flex flex-col gap-2">
                    <.link navigate={~p"/characters"} class="btn btn-primary">
                      Select Existing Character
                    </.link>
                    <.link navigate={~p"/characters/new"} class="btn btn-outline">
                      Create New Character
                    </.link>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if Enum.empty?(@zone_types) do %>
        <div class="alert alert-warning mt-8">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="stroke-current shrink-0 h-6 w-6"
            fill="none"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
          <span>No zones available yet. Please ask an administrator to create zones.</span>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("enter_zone", %{"zone-id" => zone_id}, socket) do
    character = socket.assigns.character
    zone_id = String.to_integer(zone_id)

    # Update character's current zone
    case Characters.update_character(character, %{current_zone_id: zone_id}) do
      {:ok, updated_character} ->
        handle_admin_stick_granting(character)

        # Check for zone entry achievements
        zone = Map.get_zone!(zone_id)
        handle_zone_entry_achievement(updated_character, zone)

        # Get the first room in the zone to start at
        rooms = Map.list_rooms_by_zone(zone_id)

        starting_room =
          Enum.min_by(
            rooms,
            fn room ->
              {room.x_coordinate, room.y_coordinate, room.z_coordinate}
            end,
            fn -> nil end
          )

        if starting_room do
          # Redirect to play interface with zone context
          {:noreply,
           socket
           |> put_flash(:info, "Entering #{zone.name}...")
           |> push_navigate(
             to: ~p"/play/#{updated_character.id}?zone_id=#{zone_id}&refresh_inventory=true"
           )}
        else
          {:noreply,
           socket
           |> put_flash(:error, "This zone has no rooms yet. Please notify an administrator.")}
        end

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to enter zone. Please try again.")}
    end
  end

  # Helper function to handle admin stick granting
  defp handle_admin_stick_granting(character) do
    case Users.get_user_by_character_id(character.id) do
      # Fixed: removed unused variable assignment
      %{admin: true} ->
        case AdminStick.grant_admin_stick(character.id) do
          {:ok, _} ->
            :ok

          {:error, reason} ->
            # Log the error but don't prevent zone entry
            IO.warn("Failed to grant admin stick: #{reason}")
        end

      _ ->
        :ok
    end
  end

  # Helper function to handle zone entry achievements
  defp handle_zone_entry_achievement(character, zone) do
    case Users.get_user_by_character_id(character.id) do
      %{id: user_id} ->
        case Achievements.check_zone_entry_achievements(user_id, zone.name) do
          {:ok, %Achievements.UserAchievement{}} ->
            # Achievement was awarded
            :ok

          {:ok, :already_earned} ->
            # User already has this achievement
            :ok

          {:ok, :no_achievement} ->
            # No achievement for this zone
            :ok

          {:error, _reason} ->
            # Log error but don't prevent zone entry
            :ok
        end

      _ ->
        :ok
    end
  end

  # Helper function for zone type badge colors
  defp get_zone_type_color("dungeon"), do: "badge-error"
  defp get_zone_type_color("town"), do: "badge-info"
  defp get_zone_type_color("wilderness"), do: "badge-success"
  defp get_zone_type_color("raid"), do: "badge-warning"
  defp get_zone_type_color("pvp"), do: "badge-error"
  defp get_zone_type_color("safe_zone"), do: "badge-success"
  defp get_zone_type_color(_), do: "badge-neutral"
end
