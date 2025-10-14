defmodule ShardWeb.TutorialLive.Terrain do
  use ShardWeb, :live_view
  alias Shard.Repo
  alias Shard.Npcs.Npc
  import Ecto.Query

  # Constant terrain map (compile-time)
  @tutorial_terrain_map [
    ["🏔️", "🏔️", "🏔️", "🏔️", "🏔️"],
    ["🏔️", "🌲", "🌲", "🌿", "🏔️"],
    ["🏔️", "🌲", "🌿", "🌿", "🏔️"],
    ["🏔️", "🌿", "🌿", "🌊", "🏔️"],
    ["🏔️", "🏔️", "🏔️", "🏔️", "🏔️"]
  ]

  @impl true
  def mount(_params, _session, socket) do
    tutorial_npcs = load_tutorial_npcs()
    tutorial_items = load_tutorial_items()

    socket =
      socket
      |> assign(:page_title, "Tutorial: Terrain")
      |> assign(:tutorial_npcs, tutorial_npcs)
      |> assign(:tutorial_items, tutorial_items)
      |> assign(:terrain_map, @tutorial_terrain_map)

    {:ok, socket}
  end

  defp load_tutorial_npcs do
    # Ensure Goldie is positioned at (0,0) for the tutorial
    ensure_goldie_in_tutorial()

    # Load all active NPCs in the tutorial area (coordinates 0-4, 0-4)
    from(n in Npc,
      where: n.is_active == true,
      where: n.location_x >= 0 and n.location_x <= 4,
      where: n.location_y >= 0 and n.location_y <= 4,
      where: n.location_z == 0
    )
    |> Repo.all()
  end

  defp load_tutorial_items do
    # Ensure tutorial key exists in the database
    ensure_tutorial_key_exists()
    
    # Load items from the database in the tutorial area
    alias Shard.Items.RoomItem
    
    from(ri in RoomItem,
      where: ri.location == "0,2,0",
      preload: [:item]
    )
    |> Repo.all()
    |> Enum.map(fn room_item ->
      %{
        name: room_item.item.name,
        description: room_item.item.description,
        location_x: 0,
        location_y: 2,
        location_z: 0,
        item_type: room_item.item.type,
        icon: get_item_icon(room_item.item.type),
        quantity: room_item.quantity
      }
    end)
  end

  @impl true
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
          <.minimap tutorial_npcs={@tutorial_npcs} tutorial_items={@tutorial_items} terrain_map={@terrain_map} />

          <div class="mt-4">
            <h3 class="text-lg font-semibold mb-2">NPCs in the Area</h3>
            <.npc_list npcs={@tutorial_npcs} />
          </div>

          <div class="mt-4">
            <h3 class="text-lg font-semibold mb-2">Items in the Area</h3>
            <.item_list items={@tutorial_items} />
          </div>
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

  # function component inputs
  attr :tutorial_npcs, :list, required: true
  attr :tutorial_items, :list, required: true
  attr :terrain_map, :list, required: true

  defp minimap(assigns) do
    ~H"""
    <div class="bg-gray-100 p-4 rounded-lg">
      <h3 class="font-medium mb-3">World Map</h3>
      <div class="grid grid-cols-5 gap-1 w-fit mx-auto">
        <%= for {row, row_index} <- Enum.with_index(@terrain_map) do %>
          <%= for {cell, col_index} <- Enum.with_index(row) do %>
            <div class="w-8 h-8 flex items-center justify-center text-lg border border-gray-300 rounded relative">
              {cell}
              <%= if npc_at_position(@tutorial_npcs, col_index, row_index) do %>
                <div
                  class="absolute -top-1 -right-1 w-3 h-3 bg-yellow-400 rounded-full border border-yellow-600"
                  title="NPC here"
                >
                </div>
              <% end %>
              <%= if item_at_position(@tutorial_items, col_index, row_index) do %>
                <div
                  class="absolute -bottom-1 -left-1 w-3 h-3 bg-blue-400 rounded-full border border-blue-600"
                  title="Item here"
                >
                </div>
              <% end %>
            </div>
          <% end %>
        <% end %>
      </div>
      <div class="mt-2 text-xs text-gray-600 text-center space-x-3">
        <span class="inline-flex items-center">
          <div class="w-2 h-2 bg-yellow-400 rounded-full mr-1"></div>
          NPC Location
        </span>
        <span class="inline-flex items-center">
          <div class="w-2 h-2 bg-blue-400 rounded-full mr-1"></div>
          Item Location
        </span>
      </div>
    </div>
    """
  end

  attr :npcs, :list, required: true

  defp npc_list(assigns) do
    ~H"""
    <div class="space-y-2">
      <%= for npc <- @npcs do %>
        <div class="flex items-start space-x-3 p-3 bg-white rounded-lg border border-gray-200">
          <div class="flex-shrink-0">
            {npc_icon(npc.npc_type)}
          </div>
          <div class="flex-1 min-w-0">
            <h4 class="font-medium text-gray-900">{npc.name}</h4>
            <p class="text-sm text-gray-600 line-clamp-2">{npc.description}</p>
            <div class="mt-1 flex items-center space-x-2 text-xs text-gray-500">
              <span>Level {npc.level}</span>
              <span>•</span>
              <span class="capitalize">{String.replace(npc.npc_type, "_", " ")}</span>
              <span>•</span>
              <span>Position: ({npc.location_x}, {npc.location_y})</span>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  attr :items, :list, required: true

  defp item_list(assigns) do
    ~H"""
    <div class="space-y-2">
      <%= for item <- @items do %>
        <div class="flex items-start space-x-3 p-3 bg-white rounded-lg border border-gray-200">
          <div class="flex-shrink-0">
            {item.icon}
          </div>
          <div class="flex-1 min-w-0">
            <h4 class="font-medium text-gray-900">{item.name}</h4>
            <p class="text-sm text-gray-600 line-clamp-2">{item.description}</p>
            <div class="mt-1 flex items-center space-x-2 text-xs text-gray-500">
              <span class="capitalize">{String.replace(item.item_type, "_", " ")}</span>
              <span>•</span>
              <span>Position: ({item.location_x}, {item.location_y})</span>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp npc_at_position(npcs, x, y) do
    Enum.any?(npcs, fn npc -> npc.location_x == x && npc.location_y == y end)
  end

  defp item_at_position(items, x, y) do
    Enum.any?(items, fn item -> item.location_x == x && item.location_y == y end)
  end

  defp npc_icon("quest_giver"), do: "🧙‍♂️"
  defp npc_icon("trainer"), do: "⚔️"
  defp npc_icon("merchant"), do: "🛒"
  defp npc_icon("guardian"), do: "🛡️"
  defp npc_icon("friendly"), do: "🐕"
  defp npc_icon(_), do: "👤"

  defp ensure_goldie_in_tutorial do
    case Repo.get_by(Npc, name: "Goldie") do
      nil ->
        :ok

      goldie ->
        if goldie.location_x != 0 or goldie.location_y != 0 or goldie.location_z != 0 do
          goldie
          |> Ecto.Changeset.change(%{location_x: 0, location_y: 0, location_z: 0})
          |> Repo.update()
        end
    end
  end

  defp ensure_tutorial_key_exists do
    alias Shard.Items.{Item, RoomItem}
    
    # Check if tutorial key already exists in the room
    existing_key = from(ri in RoomItem,
      where: ri.location == "0,2,0",
      join: i in Item, on: ri.item_id == i.id,
      where: i.name == "Tutorial Key"
    ) |> Repo.one()
    
    if is_nil(existing_key) do
      # Create the tutorial key item if it doesn't exist
      {:ok, key_item} = case Repo.get_by(Item, name: "Tutorial Key") do
        nil ->
          %Item{}
          |> Item.changeset(%{
            name: "Tutorial Key",
            description: "A mysterious key that might unlock something important.",
            type: "key",
            rarity: "common",
            value: 10,
            stackable: false,
            equippable: false
          })
          |> Repo.insert()
        
        existing_item ->
          {:ok, existing_item}
      end
      
      # Place the key in the room at (0,2,0)
      %RoomItem{}
      |> RoomItem.changeset(%{
        item_id: key_item.id,
        location: "0,2,0",
        quantity: 1
      })
      |> Repo.insert()
    end
  end

  defp get_item_icon("key"), do: "🗝️"
  defp get_item_icon("weapon"), do: "⚔️"
  defp get_item_icon("armor"), do: "🛡️"
  defp get_item_icon("potion"), do: "🧪"
  defp get_item_icon("scroll"), do: "📜"
  defp get_item_icon(_), do: "📦"
end
