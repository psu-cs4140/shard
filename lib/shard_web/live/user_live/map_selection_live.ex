defmodule ShardWeb.MapSelectionLive do
  use ShardWeb, :live_view
  alias Shard.Characters
  alias ShardWeb.CharacterSelectionComponent

  @impl true
  def mount(_params, _session, socket) do
    maps = [
      %{
        id: "tutorial_terrain",
        name: "Tutorial Terrain",
        description:
          "A gentle introduction to the world of Shard. Perfect for new adventurers to learn the basics.",
        difficulty: "Beginner",
        unlocked: true,
        image: "🌱"
      },
      %{
        id: "dark_forest",
        name: "Dark Forest",
        description: "Ancient woods filled with mysterious creatures and hidden secrets.",
        difficulty: "Intermediate",
        unlocked: false,
        image: "🌲"
      },
      %{
        id: "crystal_caves",
        name: "Crystal Caves",
        description:
          "Glittering underground caverns with valuable treasures and dangerous guardians.",
        difficulty: "Advanced",
        unlocked: false,
        image: "💎"
      },
      %{
        id: "volcanic_peaks",
        name: "Volcanic Peaks",
        description: "Treacherous mountain terrain with lava flows and fire elementals.",
        difficulty: "Expert",
        unlocked: false,
        image: "🌋"
      },
      %{
        id: "frozen_wastes",
        name: "Frozen Wastes",
        description: "An icy wilderness where only the strongest survive the eternal winter.",
        difficulty: "Master",
        unlocked: false,
        image: "❄️"
      },
      %{
        id: "shadow_realm",
        name: "Shadow Realm",
        description: "A dark dimension where reality bends and nightmares come alive.",
        difficulty: "Legendary",
        unlocked: false,
        image: "🌑"
      }
    ]

    user = get_current_user(socket)
    characters = load_characters(user)

    {:ok,
     assign(socket,
       maps: maps,
       characters: characters,
       show_character_modal: false,
       selected_map: nil
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gradient-to-br from-amber-50 to-orange-100 p-8">
      <div class="max-w-6xl mx-auto">
        <!-- Header -->
        <div class="text-center mb-12">
          <h1 class="text-5xl font-bold text-amber-900 mb-4">🗺️ Choose Your Adventure</h1>
          <p class="text-xl text-amber-800 mb-6">
            Select a map to begin your journey through the realms of Shard
          </p>
          <.button navigate={~p"/"} class="prairie-btn">
            ← Back to Home
          </.button>
        </div>
        
    <!-- Maps Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          <%= for map <- @maps do %>
            <div class={"relative bg-white rounded-xl shadow-lg border-2 transition-all duration-300 hover:shadow-xl #{if map.unlocked, do: "border-amber-200 hover:border-amber-300", else: "border-gray-200 opacity-60"}"}>
              <!-- Lock overlay for locked maps -->
              <%= if not map.unlocked do %>
                <div class="absolute inset-0 bg-gray-900/50 rounded-xl flex items-center justify-center z-10">
                  <div class="text-center text-white">
                    <.icon name="hero-lock-closed" class="w-12 h-12 mx-auto mb-2" />
                    <p class="font-semibold">Locked</p>
                    <p class="text-sm opacity-80">Complete previous maps to unlock</p>
                  </div>
                </div>
              <% end %>
              
    <!-- Map Card Content -->
              <div class="p-6">
                <div class="text-6xl text-center mb-4">
                  {map.image}
                </div>

                <h3 class="text-2xl font-bold text-gray-900 text-center mb-2">
                  {map.name}
                </h3>

                <div class="flex justify-center mb-4">
                  <span class={"px-3 py-1 rounded-full text-sm font-semibold #{difficulty_color(map.difficulty)}"}>
                    {map.difficulty}
                  </span>
                </div>

                <p class="text-gray-600 text-center mb-6 leading-relaxed">
                  {map.description}
                </p>

                <div class="text-center">
                  <%= if map.unlocked do %>
                    <.button
                      phx-click="select_map"
                      phx-value-map_id={map.id}
                      variant="primary"
                      class="w-full prairie-btn-primary"
                    >
                      🏇 Enter {map.name}
                    </.button>
                  <% else %>
                    <button
                      disabled
                      class="w-full px-4 py-2 bg-gray-300 text-gray-500 rounded-lg cursor-not-allowed"
                    >
                      🔒 Locked
                    </button>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        
    <!-- Footer Info -->
        <div class="mt-16 text-center">
          <div class="bg-white/80 backdrop-blur-sm rounded-lg p-6 border border-amber-200">
            <h3 class="text-xl font-semibold text-amber-900 mb-3">🌟 Adventure Awaits</h3>
            <p class="text-amber-800 mb-4">
              Each map offers unique challenges, treasures, and experiences.
              Complete maps to unlock new territories and face greater challenges!
            </p>
            <div class="flex justify-center space-x-6 text-sm text-amber-700">
              <div class="flex items-center">
                <span class="w-3 h-3 bg-green-500 rounded-full mr-2"></span> Unlocked & Ready
              </div>
              <div class="flex items-center">
                <span class="w-3 h-3 bg-gray-400 rounded-full mr-2"></span>
                Locked - Complete Prerequisites
              </div>
            </div>
          </div>
        </div>
      </div>
      
    <!-- Character Selection Modal Component -->
      <.live_component
        module={CharacterSelectionComponent}
        id="character-selection"
        show={@show_character_modal}
        characters={@characters}
        selected_map={@selected_map}
        current_user={get_current_user(socket)}
      />
    </div>
    """
  end

  @impl true
  def handle_event("select_map", %{"map_id" => map_id}, socket) do
    user = get_current_user(socket)
    characters = load_characters(user)

    {:noreply,
     assign(socket,
       show_character_modal: true,
       selected_map: map_id,
       characters: characters
     )}
  end

  @impl true
  def handle_info({:character_selected, character_id, character_name}, socket) do
    {:noreply,
     socket
     |> assign(show_character_modal: false)
     |> push_navigate(
       to:
         ~p"/play/#{socket.assigns.selected_map}?character_id=#{character_id}&character_name=#{URI.encode(character_name)}"
     )}
  end

  def handle_info(:cancel_selection, socket) do
    {:noreply, assign(socket, show_character_modal: false, selected_map: nil)}
  end

  def handle_info({:characters_updated, characters}, socket) do
    {:noreply, assign(socket, characters: characters)}
  end

  # Helper functions
  defp get_current_user(socket) do
    cond do
      socket.assigns[:current_scope] && socket.assigns.current_scope.user ->
        socket.assigns.current_scope.user

      socket.assigns[:current_user] ->
        socket.assigns.current_user

      true ->
        nil
    end
  end

  defp load_characters(nil), do: []

  defp load_characters(user) do
    Characters.get_characters_by_user(user.id)
  end

  defp difficulty_color(difficulty) do
    case difficulty do
      "Beginner" -> "bg-green-100 text-green-800"
      "Intermediate" -> "bg-blue-100 text-blue-800"
      "Advanced" -> "bg-yellow-100 text-yellow-800"
      "Expert" -> "bg-orange-100 text-orange-800"
      "Master" -> "bg-red-100 text-red-800"
      "Legendary" -> "bg-purple-100 text-purple-800"
      _ -> "bg-gray-100 text-gray-800"
    end
  end
end
