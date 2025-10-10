defmodule ShardWeb.UserLive.MinimapComponents do
  # Calculate bounds and scale factor for minimap rendering
  def calculate_minimap_bounds(rooms) do
    if Enum.empty?(rooms) do
      # Default bounds if no rooms - center around origin
      {{-5, -5, 5, 5}, 15.0}
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

      # Calculate scale to fit in 300x200 minimap with padding
      width = max_x - min_x
      height = max_y - min_y

      # Ensure minimum size to prevent division by zero
      width = max(width, 1)
      height = max(height, 1)

      # 260 to leave 20px padding on each side
      scale_x = 260 / width
      # 160 to leave 20px padding top/bottom
      scale_y = 160 / height
      scale_factor = min(scale_x, scale_y)

      # Ensure minimum scale factor for visibility
      scale_factor = max(scale_factor, 5.0)

      {{min_x, min_y, max_x, max_y}, scale_factor}
    end
  end

  # Calculate position within minimap coordinates
  def calculate_minimap_position({x, y}, {min_x, min_y, _max_x, _max_y}, scale_factor) do
    # Translate to origin and scale, then center in minimap
    # 20px padding
    scaled_x = (x - min_x) * scale_factor + 20
    # 20px padding
    scaled_y = (y - min_y) * scale_factor + 20

    # Ensure coordinates are within bounds
    scaled_x = max(10, min(scaled_x, 290))
    scaled_y = max(10, min(scaled_y, 190))

    {scaled_x, scaled_y}
  end

  # Check if a door is one-way (no return door in opposite direction)
  def is_one_way_door?(door) do
    # This is a simplified implementation - you may want to enhance this
    # based on your specific business logic for determining one-way doors

    # For now, we'll check if the door has a specific property or type
    # that indicates it's one-way, or if there's no corresponding return door
    door.door_type == "one_way" or
      (door.properties && Map.get(door.properties, "one_way", false))
  end
end
