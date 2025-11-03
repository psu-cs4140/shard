defmodule Shard.Repo.Migrations.InsertVampiresManorRooms do
  use Ecto.Migration

  def up do
    execute """
    INSERT INTO rooms (name, description, x_coordinate, y_coordinate, z_coordinate, is_public, room_type, properties, zone_id, inserted_at, updated_at)
    VALUES 
      ('Courtyard SW', NULL, -1, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Courtyard NW', NULL, -1, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Manor''s Doorstep', NULL, 0, -1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Sewer Pipe Entrance', NULL, -2, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Sewer Tunnel 1', NULL, -3, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Sewer Tunnel 2', NULL, -3, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Library', NULL, -1, -2, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Sewer Lair', NULL, -4, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Hallway W', NULL, 1, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Hallway E', NULL, 2, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Manor Lobby NW', NULL, 0, -4, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Manor Lobby CE', NULL, 3, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Manor Lobby CW', NULL, 0, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Manor Lobby SW', NULL, 0, -2, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Garden N', NULL, 1, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Garden S', NULL, 1, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Manor Lobby NE', NULL, 3, -4, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Manor Lobby SE', NULL, 3, -2, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Courtyard SE', NULL, 0, 1, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Courtyard NE', NULL, 0, 0, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Dining Hall W', NULL, 4, -4, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Dining Hall E', NULL, 5, -4, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Kitchen', NULL, 5, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Freezer', NULL, 4, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Study', NULL, -1, -3, 0, true, 'standard', '{}', 2, NOW(), NOW()),
      ('Master Bedroom', NULL, -1, -4, 0, true, 'standard', '{}', 2, NOW(), NOW());
    """
  end

  def down do
    execute """
    DELETE FROM rooms WHERE zone_id = 2;
    """
  end
end
