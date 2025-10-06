defmodule ShardWeb.UserLive.LegacyMap do
  use ShardWeb, :live_view

  # Component for individual map cells (legacy grid-based map)
  def map_cell_legacy(assigns) do
    # Define colors based on cell type
    color_class =
      case assigns.cell do
        # Wall
        0 -> "bg-gray-900"
        # Floor
        1 -> "bg-green-700"
        # Water
        2 -> "bg-blue-600"
        # Treasure
        3 -> "bg-yellow-600"
        # Unknown
        _ -> "bg-purple-600"
      end

    player_class = if assigns.is_player, do: "ring-2 ring-red-500", else: ""

    assigns = assign(assigns, color_class: color_class, player_class: player_class)

    ~H"""
    <div class={"w-6 h-6 #{@color_class} #{@player_class} border border-gray-800"}></div>
    """
  end

  # === Exits helpers ===

  # (A) Convert a cardinal direction label to a key your calc_position/3 already understands
  def dir_to_key("north"), do: "ArrowUp"
  def dir_to_key("south"), do: "ArrowDown"
  def dir_to_key("east"), do: "ArrowRight"
  def dir_to_key("west"), do: "ArrowLeft"
  def dir_to_key("northeast"), do: "northeast"
  def dir_to_key("northwest"), do: "northwest"
  def dir_to_key("southeast"), do: "southeast"
  def dir_to_key("southwest"), do: "southwest"
  def dir_to_key(_), do: nil


end
