defmodule ShardWeb.TutorialLive.Terrain do
  use ShardWeb, :live_view

  @tutorial_terrain_map [
    ["🏔️", "🏔️", "🏔️", "🏔️", "🏔️"],
    ["🏔️", "🌲", "🌲", "🌿", "🏔️"],
    ["🏔️", "🌲", "🌿", "🌿", "🏔️"],
    ["🏔️", "🌿", "🌿", "🌊", "🏔️"],
    ["🏔️", "🏔️", "🏔️", "🏔️", "🏔️"]
  ]

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Tutorial: Terrain")}
  end

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto p-6">
      <h1 class="text-3xl font-bold mb-6">Tutorial: Understanding Terrain</h1>
      
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div class="space-y-4">
          <h2 class="text-2xl font-semibold">Terrain Types</h2>
          
          <div class="space-y-3">
            <div class="flex items-center space-x-3">
              <span class="text-2xl">🏔️</span>
              <div>
                <h3 class="font-medium">Mountains</h3>
                <p class="text-sm text-gray-600">Impassable terrain that blocks movement</p>
              </div>
            </div>
            
            <div class="flex items-center space-x-3">
              <span class="text-2xl">🌲</span>
              <div>
                <h3 class="font-medium">Forest</h3>
                <p class="text-sm text-gray-600">Dense woodland that slows movement</p>
              </div>
            </div>
            
            <div class="flex items-center space-x-3">
              <span class="text-2xl">🌿</span>
              <div>
                <h3 class="font-medium">Plains</h3>
                <p class="text-sm text-gray-600">Open grassland with normal movement</p>
              </div>
            </div>
            
            <div class="flex items-center space-x-3">
              <span class="text-2xl">🌊</span>
              <div>
                <h3 class="font-medium">Water</h3>
                <p class="text-sm text-gray-600">Rivers and lakes that require swimming</p>
              </div>
            </div>
          </div>
        </div>
        
        <div class="space-y-4">
          <h2 class="text-2xl font-semibold">Tutorial Map</h2>
          <.minimap />
        </div>
      </div>
      
      <div class="mt-8 p-4 bg-blue-50 rounded-lg">
        <h3 class="font-semibold text-blue-900 mb-2">Navigation Tips</h3>
        <ul class="text-sm text-blue-800 space-y-1">
          <li>• Use the minimap to plan your route</li>
          <li>• Avoid mountains as they cannot be crossed</li>
          <li>• Forests slow you down but provide cover</li>
          <li>• Plains offer the fastest travel</li>
          <li>• Water requires special equipment or abilities</li>
        </ul>
      </div>
    </div>
    """
  end

  defp minimap(assigns) do
    ~H"""
    <div class="bg-gray-100 p-4 rounded-lg">
      <h3 class="font-medium mb-3">World Map</h3>
      <div class="grid grid-cols-5 gap-1 w-fit mx-auto">
        <%= for {row, row_index} <- Enum.with_index(@tutorial_terrain_map) do %>
          <%= for {cell, col_index} <- Enum.with_index(row) do %>
            <div class="w-8 h-8 flex items-center justify-center text-lg border border-gray-300 rounded">
              <%= cell %>
            </div>
          <% end %>
        <% end %>
      </div>
    </div>
    """
  end
end
