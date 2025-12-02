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

    # Get template zones (zones ending with "-template")
    template_zones = 
      Map.list_active_zones()
      |> Enum.filter(&String.ends_with?(&1.zone_id, "-template"))
      |> Enum.sort_by(& &1.display_order)

    {:noreply,
     socket
     |> assign(:template_zones, template_zones)
     |> assign(:character, character)
     |> assign(:page_title, "Select Zone")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container mx-auto px-6 py-12 max-w-7xl">
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

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mt-12">
        <%= for zone <- @template_zones do %>
          <div class="card bg-base-200 shadow-xl hover:shadow-2xl transition-all duration-300 rounded-2xl border border-base-300/50">
            <div class="card-body p-8">
              <h2 class="card-title">
                {zone.name}
                <div class={[
                  "badge",
                  get_zone_type_color(zone.zone_type)
                ]}>
                  {String.capitalize(zone.zone_type)}
                </div>
              </h2>

              <p class="text-sm opacity-80 min-h-[4rem]">{zone.description}</p>

              <div class="divider my-4"></div>

              <div class="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <span class="font-semibold">Level Range:</span>
                  <br />
                  {zone.min_level}-{zone.max_level || "∞"}
                </div>
                <div>
                  <span class="font-semibold">Rooms:</span>
                  <br />
                  {length(Map.list_rooms_by_zone(zone.id))}
                </div>
              </div>

              <div class="card-actions justify-end mt-4">
                <%= if @character do %>
                  <div class="flex gap-3">
                    <.button
                      phx-click="enter_zone"
                      phx-value-zone_name={zone.name}
                      phx-value-instance_type="singleplayer"
                      class="bg-orange-600 hover:bg-orange-700 text-white border-orange-600 hover:border-orange-700 flex-1 transition-all duration-300 ease-in-out transform hover:scale-105 hover:shadow-lg hover:shadow-orange-500/25 hover:brightness-110 active:scale-95 rounded-xl px-4 py-3"
                    >
                      <svg class="w-4 h-4 mr-1 transition-transform duration-300 group-hover:rotate-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"></path>
                      </svg>
                      <span class="transition-all duration-300">Singleplayer</span>
                    </.button>
                    <.button
                      phx-click="enter_zone"
                      phx-value-zone_name={zone.name}
                      phx-value-instance_type="multiplayer"
                      class="btn-secondary flex-1 transition-all duration-300 ease-in-out transform hover:scale-105 hover:shadow-lg hover:shadow-secondary/25 hover:brightness-110 active:scale-95 rounded-xl px-4 py-3"
                    >
                      <svg class="w-4 h-4 mr-1 transition-transform duration-300 group-hover:rotate-12" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path>
                      </svg>
                      <span class="transition-all duration-300">Multiplayer</span>
                    </.button>
                  </div>
                <% else %>
                  <div class="flex flex-col gap-3">
                    <.link navigate={~p"/characters"} class="btn btn-primary rounded-xl px-4 py-3">
                      Select Existing Character
                    </.link>
                    <.link navigate={~p"/characters/new"} class="btn btn-outline rounded-xl px-4 py-3">
                      Create New Character
                    </.link>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        <% end %>
      </div>

      <%= if Enum.empty?(@template_zones) do %>
        <div class="alert alert-warning mt-12 rounded-2xl border border-warning/20 shadow-lg">
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
  def handle_event("enter_zone", %{"zone_name" => zone_name, "instance_type" => instance_type}, socket) do
    character = socket.assigns.character
    user = Users.get_user_by_character_id(character.id)

    # Find the template zone by name
    template_zone = Enum.find(socket.assigns.template_zones, &(&1.name == zone_name))

    case template_zone do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Zone '#{zone_name}' not found. Please try again.")}

      zone ->
        # For singleplayer, we can directly use the template zone
        # Update character's current zone to point to the template zone
        case Characters.update_character(character, %{current_zone_id: zone.id}) do
          {:ok, updated_character} ->
            handle_admin_stick_granting(character)

            # Check for zone entry achievements
            handle_zone_entry_achievement(updated_character, zone)

            # Get the first room in the zone to start at
            rooms = Map.list_rooms_by_zone(zone.id)

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
               |> put_flash(:info, "Entering #{zone.name} (#{instance_type})...")
               |> push_navigate(
                 to: ~p"/play/#{updated_character.id}?zone_id=#{zone.id}&refresh_inventory=true"
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
