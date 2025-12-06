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

    # Get all active zones
    all_zones = Map.list_active_zones()

    zones =
      all_zones
      |> Enum.sort_by(& &1.display_order)

    # Get user zone progress if character exists
    zone_progress_map =
      if character do
        user = Users.get_user_by_character_id(character.id)

        if user do
          Users.list_user_zone_progress(user.id)
          |> Enum.into(%{}, fn progress -> {progress.zone_id, progress.progress} end)
        else
          %{}
        end
      else
        %{}
      end
      |> ensure_special_zones_accessible(zones)
      |> ensure_mines_accessible(zones)

    {:noreply,
     socket
     |> assign(:zones, zones)
     |> assign(:character, character)
     |> assign(:zone_progress_map, zone_progress_map)
     |> assign(:page_title, "Select Zone")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="min-h-screen bg-black">
        <div class="container mx-auto px-6 py-12 max-w-7xl">
          <.header>
            <span class="text-white">Select a Dungeon to Explore</span>
            <:subtitle>
              <%= if @character do %>
                <span class="text-gray-300">
                  Playing as: {@character.name} (Level {@character.level} {@character.class})
                </span>
              <% else %>
                <span class="text-gray-400">Choose a dungeon to begin your dark adventure</span>
              <% end %>
            </:subtitle>
          </.header>

          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mt-12">
            <%= for zone <- @zones do %>
              <% zone_progress = Kernel.get_in(@zone_progress_map, [zone.id]) || "locked" %>
              <% is_accessible = zone_progress in ["in_progress", "completed"] %>
              <div class={[
                "card shadow-xl transition-all duration-300 rounded-2xl border-2",
                if(is_accessible,
                  do: "bg-white hover:shadow-2xl hover:shadow-gray-400/50 border-gray-300",
                  else: "bg-gray-200 border-gray-400 opacity-60"
                )
              ]}>
                <div class="card-body p-8">
                  <h2 class={[
                    "card-title",
                    if(is_accessible, do: "text-gray-900", else: "text-gray-500")
                  ]}>
                    {zone.name}
                    <div class={[
                      "badge",
                      if(is_accessible,
                        do: "border-gray-400 " <> get_zone_type_color(zone.zone_type),
                        else: "border-gray-500 bg-gray-300 text-gray-600"
                      )
                    ]}>
                      <%= if !is_accessible do %>
                        🔒
                      <% end %>
                      {String.capitalize(zone.zone_type)}
                    </div>
                  </h2>

                  <p class={[
                    "text-sm min-h-[4rem]",
                    if(is_accessible, do: "text-gray-700", else: "text-gray-500")
                  ]}>
                    {if is_accessible,
                      do: zone.description,
                      else: "This zone is locked. Complete previous zones to unlock."}
                  </p>

                  <div class="divider my-4 border-gray-300"></div>

                  <div class={[
                    "grid grid-cols-2 gap-2 text-sm",
                    if(is_accessible, do: "text-gray-700", else: "text-gray-500")
                  ]}>
                    <div>
                      <span class={[
                        "font-semibold",
                        if(is_accessible, do: "text-gray-900", else: "text-gray-400")
                      ]}>
                        Level Range:
                      </span>
                      <br />
                      <span class={if(is_accessible, do: "text-gray-700", else: "text-gray-500")}>
                        {zone.min_level}-{zone.max_level || "∞"}
                      </span>
                    </div>
                    <div>
                      <span class={[
                        "font-semibold",
                        if(is_accessible, do: "text-gray-900", else: "text-gray-400")
                      ]}>
                        Rooms:
                      </span>
                      <br />
                      <span class={if(is_accessible, do: "text-gray-700", else: "text-gray-500")}>
                        {if is_accessible, do: length(Map.list_rooms_by_zone(zone.id)), else: "???"}
                      </span>
                    </div>
                  </div>

                  <div class="card-actions justify-end mt-4">
                    <%= if @character do %>
                      <%= if is_accessible do %>
                        <div class="flex gap-3">
                          <.button
                            phx-click="enter_zone"
                            phx-value-zone_name={zone.name}
                            phx-value-instance_type="singleplayer"
                            class="bg-gray-800 hover:bg-gray-700 text-white border-gray-600 hover:border-gray-500 flex-1 transition-all duration-300 ease-in-out transform hover:scale-105 hover:shadow-lg hover:shadow-gray-500/25 hover:brightness-110 active:scale-95 rounded-xl px-4 py-3"
                          >
                            <svg
                              class="w-4 h-4 mr-1 transition-transform duration-300 group-hover:rotate-12"
                              fill="none"
                              stroke="currentColor"
                              viewBox="0 0 24 24"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                              >
                              </path>
                            </svg>
                            <span class="transition-all duration-300">Singleplayer</span>
                          </.button>
                          <.button
                            phx-click="enter_zone"
                            phx-value-zone_name={zone.name}
                            phx-value-instance_type="multiplayer"
                            class="bg-gray-900 hover:bg-gray-800 text-white border-gray-700 hover:border-gray-600 flex-1 transition-all duration-300 ease-in-out transform hover:scale-105 hover:shadow-lg hover:shadow-gray-500/25 hover:brightness-110 active:scale-95 rounded-xl px-4 py-3"
                          >
                            <svg
                              class="w-4 h-4 mr-1 transition-transform duration-300 group-hover:rotate-12"
                              fill="none"
                              stroke="currentColor"
                              viewBox="0 0 24 24"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
                              >
                              </path>
                            </svg>
                            <span class="transition-all duration-300">Multiplayer</span>
                          </.button>
                        </div>
                      <% else %>
                        <div class="flex gap-3">
                          <button
                            disabled
                            class="btn bg-gray-700 text-gray-400 border-gray-600 flex-1 rounded-xl px-4 py-3 cursor-not-allowed"
                          >
                            🔒 Locked
                          </button>
                        </div>
                      <% end %>
                    <% else %>
                      <div class="flex flex-col gap-3">
                        <.link
                          navigate={~p"/characters"}
                          class="btn bg-gray-800 hover:bg-gray-700 text-white border-gray-600 rounded-xl px-4 py-3"
                        >
                          Select Existing Character
                        </.link>
                        <.link
                          navigate={~p"/characters/new"}
                          class="btn bg-gray-900 hover:bg-gray-800 text-white border-gray-700 rounded-xl px-4 py-3"
                        >
                        >
                          Select Existing Character
                        </.link>
                        <.link
                          navigate={~p"/characters/new"}
                          class="btn bg-gray-900 hover:bg-gray-800 text-white border-gray-700 rounded-xl px-4 py-3"
                        >
                          Create New Character
                        </.link>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>

          <%= if Enum.empty?(@zones) do %>
            <div class="alert bg-gray-100 border-2 border-gray-300 text-gray-800 mt-12 rounded-2xl shadow-lg">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="stroke-current shrink-0 h-6 w-6 text-gray-600"
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
              <span>No dungeons available yet. Please ask an administrator to create zones.</span>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event(
        "enter_zone",
        %{"zone_name" => zone_name, "instance_type" => instance_type},
        socket
      ) do
    character = socket.assigns.character
    _user = Users.get_user_by_character_id(character.id)

    # Find the zone by name
    zone = Enum.find(socket.assigns.zones, &(&1.name == zone_name))

    case zone do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Zone '#{zone_name}' not found. Please try again.")}

      zone ->
        cond do
          zone.slug == "mines" ->
            handle_mines_entry(socket, character, zone)

          zone.slug == "whispering_forest" ->
            handle_forest_entry(socket, character, zone, instance_type)

          true ->
            handle_standard_zone_entry(socket, character, zone, instance_type)
        end
    end
  end

  # Ensure Mines and Whispering Forest are always accessible regardless of progress or level
  defp ensure_special_zones_accessible(progress_map, zones) do
    progress_map
    |> allow_zone(zones, "mines")
    |> allow_zone(zones, "whispering_forest")
  end

  defp allow_zone(progress_map, zones, slug) do
    case Enum.find(zones, &(&1.slug == slug)) do
      nil -> progress_map
      %{id: id} -> Elixir.Map.put(progress_map, id, "in_progress")
    end
  end

  # Handle entry to the Mines zone (mining system)
  defp handle_mines_entry(socket, character, zone) do
    case Characters.update_character(character, %{current_zone_id: zone.id}) do
      {:ok, updated_character} ->
        {:noreply,
         socket
         |> assign(:character, updated_character)
         |> put_flash(
           :info,
           "You Descend into the dark, echoing mines.\nThe walls shimmer with minerals waiting to be unearthed.\nEverything you gather here can be sold for gold once you return to town.\nTo begin mining, type mine start\nTo pack up and leave, type mine stop"
         )
         |> push_navigate(
           to: ~p"/play/#{updated_character.id}?zone_id=#{zone.id}&refresh_inventory=true"
         )}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to enter the Mines. Please try again.")}
    end
  end

  defp handle_forest_entry(socket, character, zone, _instance_type) do
    case Characters.update_character(character, %{current_zone_id: zone.id}) do
      {:ok, updated_character} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "You step foot into the Whispering Forest.\nYour nose fills with the scent of pine and fresh earth.\nHere you can chop wood, gather sticks and seeds, and even find mushrooms and rare resin that you can collect and sell for gold.\nType chop start to start chopping\nType chop stop to stop chopping"
         )
         |> push_navigate(
           to: ~p"/play/#{updated_character.id}?zone_id=#{zone.id}&refresh_inventory=true"
         )}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to enter the Whispering Forest. Please try again.")}
    end
  end

  # Ensure Mines is always accessible regardless of progress or level
  defp ensure_mines_accessible(progress_map, zones) do
    case Enum.find(zones, &(&1.slug == "mines")) do
      nil -> progress_map
      %{id: id} -> Elixir.Map.put(progress_map, id, "in_progress")
    end
  end

  # Handle entry to standard zones (dungeons, etc.)
  defp handle_standard_zone_entry(socket, character, zone, instance_type) do
    # Check if user has access to this zone
    zone_progress = socket.assigns.zone_progress_map[zone.id] || "locked"

    if zone_progress in ["in_progress", "completed"] do
      # For singleplayer, we can directly use the zone
      # Update character's current zone to point to the zone
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
             |> put_flash(
               :error,
               "This zone has no rooms yet. Please notify an administrator."
             )}
          end

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to enter zone. Please try again.")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "This zone is locked. Complete previous zones to unlock it.")}
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
  defp get_zone_type_color("dungeon"), do: "bg-gray-700 text-white"
  defp get_zone_type_color("town"), do: "bg-gray-600 text-white"
  defp get_zone_type_color("wilderness"), do: "bg-gray-800 text-white"
  defp get_zone_type_color("raid"), do: "bg-gray-500 text-white"
  defp get_zone_type_color("pvp"), do: "bg-gray-700 text-white"
  defp get_zone_type_color("safe_zone"), do: "bg-gray-600 text-white"
  defp get_zone_type_color(_), do: "bg-gray-900 text-white"
end
