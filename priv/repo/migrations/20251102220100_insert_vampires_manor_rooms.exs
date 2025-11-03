defmodule Shard.Repo.Migrations.InsertVampiresManorRooms do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO rooms (id, name, description, x_coordinate, y_coordinate, z_coordinate, is_public, room_type, properties, zone_id, inserted_at, updated_at)
    VALUES 
      (19, 'Courtyard NE', NULL, 0, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (20, 'Courtyard NW', NULL, -1, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (21, 'Courtyard SW', NULL, -1, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (22, 'Courtyard SE', NULL, 0, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (23, 'Manor''s Doorstep', NULL, 0, -1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (24, 'Garden N', NULL, 1, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (25, 'Garden S', NULL, 1, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (26, 'Sewer Pipe Entrance', NULL, -2, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (27, 'Sewer Tunnel 1', NULL, -3, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (28, 'Sewer Tunnel 2', NULL, -3, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (29, 'Sewer Lair', NULL, -4, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (31, 'Manor Lobby SW', NULL, 0, -2, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (33, 'Manor Lobby CW', NULL, 0, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (34, 'Manor Lobby NW', NULL, 0, -4, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (35, 'Library', NULL, -1, -2, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (36, 'Hallway W', NULL, 1, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (37, 'Hallway E', NULL, 2, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (38, 'Manor Lobby CE', NULL, 3, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (39, 'Manor Lobby NE', NULL, 3, -4, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (40, 'Manor Lobby SE', NULL, 3, -2, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (41, 'Dining Hall W', NULL, 4, -4, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (42, 'Dining Hall E', NULL, 5, -4, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (43, 'Kitchen', NULL, 5, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (45, 'Freezer', NULL, 4, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (46, 'Study', NULL, -1, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      (47, 'Master Bedroom', NULL, -1, -4, 0, true, 'standard', '{}', 2, NOW(), NOW());
    """
  end

  def down do
    execute """
    DELETE FROM rooms WHERE zone_id = 2;
    """
  end
end
