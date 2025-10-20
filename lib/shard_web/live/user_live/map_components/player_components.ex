defmodule ShardWeb.UserLive.MapComponents.PlayerComponents do
  @moduledoc """
  Components for rendering player markers in maps and minimaps.
  """
  
  use ShardWeb, :live_view
  import ShardWeb.UserLive.MapComponents.RoomComponents

  # -- Helpers ----------------------------------------------------
  defp format_position({x, y}), do: "{#{x}, #{y}}"
  defp format_position({x, y, z}), do: "{#{x}, #{y}, #{z}}"
  defp format_position(other), do: inspect(other)

  # Component for player marker in full map
  def player_marker_full(assigns) do
    {x_pos, y_pos} =
      calculate_full_map_position(
        assigns.position,
        assigns.bounds,
        assigns.scale_factor
      )

    assigns = assign(assigns, x_pos: x_pos, y_pos: y_pos)

    ~H"""
    <circle
      cx={@x_pos}
      cy={@y_pos}
      r="12"
      fill="#ef4444"
      stroke="#ffffff"
      stroke-width="3"
      opacity="0.9"
    >
      <title>Player at {format_position(@position)} (no room)</title>
    </circle>
    """
  end

  # Component for player marker in minimap
  def player_marker(assigns) do
    {x_pos, y_pos} =
      ShardWeb.UserLive.MinimapComponents.calculate_minimap_position(
        assigns.position,
        assigns.bounds,
        assigns.scale_factor
      )

    assigns = assign(assigns, x_pos: x_pos, y_pos: y_pos)

    ~H"""
    <circle
      cx={@x_pos}
      cy={@y_pos}
      r="8"
      fill="#ef4444"
      stroke="#ffffff"
      stroke-width="2"
      opacity="0.9"
    >
      <title>Player at {format_position(@position)} (no room)</title>
    </circle>
    """
  end
end
