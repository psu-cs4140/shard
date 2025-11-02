defmodule Shard.Repo.Migrations.AddExampleZoneWithRooms do
  use Ecto.Migration

  def up do
    # Insert the zone first
    zone_id = insert_zone()
    
    # Insert rooms for this zone
    insert_rooms(zone_id)
    
    # Insert doors to connect the rooms
    insert_doors(zone_id)
  end

  def down do
    # Clean up in reverse order
    delete_doors_for_zone("example_zone")
    delete_rooms_for_zone("example_zone")
    delete_zone("example_zone")
  end

  defp insert_zone do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    {1, [%{id: zone_id}]} = repo().insert_all("zones", [
      %{
        name: "Example Zone",
        slug: "example_zone",
        description: "An example zone with multiple connected rooms",
        zone_type: "dungeon",
        min_level: 1,
        max_level: 5,
        is_public: true,
        inserted_at: now,
        updated_at: now
      }
    ], returning: [:id])
    
    zone_id
  end

  defp insert_rooms(zone_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    # Define room data with coordinates
    rooms = [
      %{
        name: "Entrance Hall",
        description: "A grand entrance hall with high ceilings and marble floors.",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        zone_id: zone_id,
        is_public: true,
        room_type: "normal",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Northern Chamber",
        description: "A dimly lit chamber with ancient stone walls.",
        x_coordinate: 0,
        y_coordinate: 1,
        z_coordinate: 0,
        zone_id: zone_id,
        is_public: true,
        room_type: "normal",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Eastern Corridor",
        description: "A narrow corridor stretching into darkness.",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        zone_id: zone_id,
        is_public: true,
        room_type: "normal",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Treasure Room",
        description: "A hidden chamber filled with glittering treasures.",
        x_coordinate: 1,
        y_coordinate: 1,
        z_coordinate: 0,
        zone_id: zone_id,
        is_public: true,
        room_type: "special",
        inserted_at: now,
        updated_at: now
      }
    ]
    
    repo().insert_all("rooms", rooms)
  end

  defp insert_doors(zone_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    
    # Get room IDs by coordinates for this zone
    entrance_hall = get_room_by_coordinates(zone_id, 0, 0, 0)
    northern_chamber = get_room_by_coordinates(zone_id, 0, 1, 0)
    eastern_corridor = get_room_by_coordinates(zone_id, 1, 0, 0)
    treasure_room = get_room_by_coordinates(zone_id, 1, 1, 0)
    
    # Define door connections
    doors = [
      # Entrance Hall <-> Northern Chamber
      %{
        name: "Northern Door",
        description: "A heavy wooden door leading north.",
        from_room_id: entrance_hall.id,
        to_room_id: northern_chamber.id,
        direction: "north",
        is_locked: false,
        key_required: nil,
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Southern Door",
        description: "A heavy wooden door leading south.",
        from_room_id: northern_chamber.id,
        to_room_id: entrance_hall.id,
        direction: "south",
        is_locked: false,
        key_required: nil,
        inserted_at: now,
        updated_at: now
      },
      
      # Entrance Hall <-> Eastern Corridor
      %{
        name: "Eastern Door",
        description: "An iron door leading east.",
        from_room_id: entrance_hall.id,
        to_room_id: eastern_corridor.id,
        direction: "east",
        is_locked: false,
        key_required: nil,
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Western Door",
        description: "An iron door leading west.",
        from_room_id: eastern_corridor.id,
        to_room_id: entrance_hall.id,
        direction: "west",
        is_locked: false,
        key_required: nil,
        inserted_at: now,
        updated_at: now
      },
      
      # Eastern Corridor <-> Treasure Room (locked)
      %{
        name: "Treasure Door",
        description: "A golden door with intricate locks.",
        from_room_id: eastern_corridor.id,
        to_room_id: treasure_room.id,
        direction: "north",
        is_locked: true,
        key_required: "Golden Key",
        inserted_at: now,
        updated_at: now
      },
      %{
        name: "Exit Door",
        description: "A golden door leading back to the corridor.",
        from_room_id: treasure_room.id,
        to_room_id: eastern_corridor.id,
        direction: "south",
        is_locked: false,
        key_required: nil,
        inserted_at: now,
        updated_at: now
      }
    ]
    
    repo().insert_all("doors", doors)
  end

  defp get_room_by_coordinates(zone_id, x, y, z) do
    repo().one!(
      from r in "rooms",
      where: r.zone_id == ^zone_id and 
             r.x_coordinate == ^x and 
             r.y_coordinate == ^y and 
             r.z_coordinate == ^z,
      select: %{id: r.id}
    )
  end

  defp delete_doors_for_zone(zone_slug) do
    repo().delete_all(
      from d in "doors",
      join: fr in "rooms", on: d.from_room_id == fr.id,
      join: z in "zones", on: fr.zone_id == z.id,
      where: z.slug == ^zone_slug
    )
  end

  defp delete_rooms_for_zone(zone_slug) do
    repo().delete_all(
      from r in "rooms",
      join: z in "zones", on: r.zone_id == z.id,
      where: z.slug == ^zone_slug
    )
  end

  defp delete_zone(zone_slug) do
    repo().delete_all(
      from z in "zones",
      where: z.slug == ^zone_slug
    )
  end
end
