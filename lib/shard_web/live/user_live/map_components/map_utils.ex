defmodule ShardWeb.UserLive.MapComponents.MapUtils do
  @moduledoc """
  Utility functions for map calculations and bounds.
  """

  # Calculate bounds and scale factor for full map rendering
  def calculate_map_bounds(rooms) do
    if Enum.empty?(rooms) do
      # Default bounds if no rooms - center around origin
      {{-5, -5, 5, 5}, 30.0}
    else
      x_coords = Enum.map(rooms, & &1.x_coordinate)
      y_coords = Enum.map(rooms, & &1.y_coordinate)

      min_x = Enum.min(x_coords)
      max_x = Enum.max(x_coords)
      min_y = Enum.min(y_coords)
      max_y = Enum.max(y_coords)

      # Add padding around the bounds
      padding = 2
      min_x = min_x - padding
      max_x = max_x + padding
      min_y = min_y - padding
      max_y = max_y + padding

      # Calculate scale to fit in 600x400 map with padding
      width = max_x - min_x
      height = max_y - min_y

      # Ensure minimum size to prevent division by zero
      width = max(width, 1)
      height = max(height, 1)

      # 560 to leave 20px padding on each side
      scale_x = 560 / width
      # 360 to leave 20px padding top/bottom
      scale_y = 360 / height
      scale_factor = min(scale_x, scale_y)

      # Ensure minimum scale factor for visibility
      scale_factor = max(scale_factor, 10.0)

      {{min_x, min_y, max_x, max_y}, scale_factor}
    end
  end
end
