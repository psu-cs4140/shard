# Zone System Implementation Guide

## Overview

The zone system allows for multiple independent maps/areas in the game, each with their own coordinate systems. This means you can create distinct game areas like "Vampire Castle", "Elven Forest", "Tutorial Area", etc., where each zone can have rooms at the same coordinates without conflict.

## What Was Implemented

### 1. Database Schema

**New Table: `zones`**
- `id` - Primary key
- `name` - Unique zone name (e.g., "Vampire Castle")
- `slug` - URL-friendly identifier (e.g., "vampire-castle")
- `description` - Zone description
- `zone_type` - Type of zone (standard, dungeon, town, wilderness, raid, pvp, safe_zone)
- `min_level` - Recommended minimum player level
- `max_level` - Recommended maximum player level
- `is_public` - Whether the zone is accessible to all players
- `is_active` - Whether the zone is currently active
- `properties` - JSON field for extensible data
- `display_order` - Sort order for UI display
- Timestamps

**Updated Table: `rooms`**
- Added `zone_id` - Foreign key to zones table
- Updated unique constraint from `(x, y, z)` to `(zone_id, x, y, z)`
  - This allows multiple zones to have rooms at the same coordinates

### 2. Schema Modules

**lib/shard/map/zone.ex**
- New Zone schema with validations
- Zone types: standard, dungeon, town, wilderness, raid, pvp, safe_zone
- Level range validation
- Slug format validation (lowercase alphanumeric with hyphens)

**lib/shard/map/room.ex**
- Added `belongs_to :zone` relationship
- Updated changeset to include zone_id
- Updated unique constraint to be zone-scoped

### 3. Context Functions

**lib/shard/map.ex** - New Zone Functions:
- `list_zones/0` - Get all zones
- `list_active_zones/0` - Get active zones ordered by display_order
- `get_zone!/1` - Get zone by ID
- `get_zone_by_slug/1` - Get zone by slug
- `create_zone/1` - Create a new zone
- `update_zone/2` - Update a zone
- `delete_zone/1` - Delete a zone
- `change_zone/2` - Get changeset for zone

**Updated Room Functions:**
- `list_rooms_by_zone/1` - Get all rooms in a specific zone
- `get_room_by_coordinates/4` - Get room by zone_id and coordinates (NEW SIGNATURE)
- `get_room_by_coordinates_legacy/3` - Backwards compatible function

### 4. Migrations

1. **20251101154803_create_zones.exs**
   - Creates zones table with all fields and indexes

2. **20251101154918_add_zone_id_to_rooms.exs**
   - Adds zone_id column to rooms (nullable)
   - Drops old coordinate-only unique constraint
   - Creates new zone-scoped coordinate constraint
   - Fully reversible

3. **20251101155408_backfill_existing_rooms_with_default_zone.exs**
   - Creates a "Legacy Map" zone for existing rooms
   - Assigns all existing rooms to this zone
   - Ensures backwards compatibility

### 5. Seed Data

**priv/repo/seeds/zones_seed.exs**
- Example seed file demonstrating zone creation
- Creates 3 sample zones:
  - Tutorial Area (3x3 grid)
  - Vampire Castle (4x4 grid)
  - Elven Forest (3x3 grid)
- Shows how multiple zones can use same coordinates
- Includes door creation between rooms within each zone

## Usage Examples

### Creating a New Zone

```elixir
alias Shard.Map

{:ok, vampire_zone} = Map.create_zone(%{
  name: "Vampire Castle",
  slug: "vampire-castle",
  description: "A dark and foreboding castle ruled by ancient vampires.",
  zone_type: "dungeon",
  min_level: 10,
  max_level: 20,
  is_public: true,
  is_active: true,
  display_order: 2,
  properties: %{
    "atmosphere" => "dark",
    "has_boss" => true,
    "recommended_party_size" => 4
  }
})
```

### Creating Rooms in a Zone

```elixir
# Create multiple rooms at the same coordinates as other zones
{:ok, room} = Map.create_room(%{
  name: "Castle Entrance",
  description: "The imposing entrance to the vampire castle",
  zone_id: vampire_zone.id,
  x_coordinate: 0,
  y_coordinate: 0,
  z_coordinate: 0,
  is_public: true,
  room_type: "standard"
})
```

### Querying Rooms by Zone

```elixir
# Get all rooms in a specific zone
rooms = Map.list_rooms_by_zone(vampire_zone.id)

# Get a specific room by coordinates within a zone
room = Map.get_room_by_coordinates(vampire_zone.id, 0, 0, 0)
```

### Getting All Active Zones

```elixir
# Get zones ordered by display_order
zones = Map.list_active_zones()
```

## Benefits

✅ **Multiple Independent Maps** - Create unlimited zones with their own coordinate systems
✅ **No Coordinate Conflicts** - Different zones can have rooms at (0,0,0)
✅ **Better Organization** - Group related rooms logically
✅ **Referential Integrity** - Proper foreign key relationships
✅ **Flexible Querying** - Easy to filter by zone
✅ **Extensible** - Properties field for zone-specific metadata
✅ **Backwards Compatible** - Legacy rooms preserved in "Legacy Map" zone

## Migration Path for Existing Code

### Code That Needs Updating

Several LiveView modules currently use `get_room_by_coordinates/2` which has been changed to require a zone_id. These warnings are shown during compilation:

- `lib/shard_web/live/character_live/index.ex`
- `lib/shard_web/live/user_live/movement.ex`
- `lib/shard_web/live/user_live/command_parsers.ex`
- `lib/shard_web/live/user_live/commands1.ex`
- `lib/shard_web/live/user_live/map_helpers.ex`

### Recommended Updates

**Option 1: Use Legacy Function (Quick Fix)**
```elixir
# Replace:
room = GameMap.get_room_by_coordinates(x, y)

# With:
room = GameMap.get_room_by_coordinates_legacy(x, y)
```

**Option 2: Add Zone Context (Proper Fix)**
```elixir
# Determine the current zone (from character, session, or context)
current_zone_id = character.current_zone_id || get_default_zone_id()

# Then use the zone-scoped function
room = GameMap.get_room_by_coordinates(current_zone_id, x, y)
```

### Character Schema Enhancement

Consider adding a `current_zone_id` field to characters to track which zone they're currently in:

```elixir
# Migration
alter table(:characters) do
  add :current_zone_id, references(:zones, on_delete: :nilify_all)
end

# Schema
belongs_to :current_zone, Shard.Map.Zone, foreign_key: :current_zone_id
```

## Testing the Implementation

### 1. Verify Migrations

```bash
mix ecto.migrations
# Should show all three zone migrations as "up"
```

### 2. Check Database

```sql
-- View zones
SELECT * FROM zones;

-- View rooms with their zones
SELECT r.id, r.name, r.x_coordinate, r.y_coordinate, z.name as zone_name
FROM rooms r
LEFT JOIN zones z ON r.zone_id = z.id
ORDER BY z.name, r.x_coordinate, r.y_coordinate;

-- Count rooms per zone
SELECT z.name, COUNT(r.id) as room_count
FROM zones z
LEFT JOIN rooms r ON r.zone_id = z.id
GROUP BY z.id, z.name;
```

### 3. Run the Example Seeds

```bash
# This will create 3 example zones with rooms
mix run priv/repo/seeds/zones_seed.exs
```

### 4. Test in IEx

```elixir
# Start IEx
iex -S mix

# Test zone creation
alias Shard.Map
{:ok, zone} = Map.create_zone(%{name: "Test Zone", slug: "test-zone"})

# Create rooms in the zone
{:ok, room} = Map.create_room(%{
  name: "Test Room", 
  zone_id: zone.id, 
  x_coordinate: 0, 
  y_coordinate: 0
})

# Query by zone
rooms = Map.list_rooms_by_zone(zone.id)
room = Map.get_room_by_coordinates(zone.id, 0, 0, 0)
```

## Future Enhancements

### Zone Portals
Consider implementing portals that allow travel between zones:

```elixir
# Add to Door schema
field :is_portal, :boolean, default: false
field :portal_destination_zone_id, :integer

# This would allow doors to connect rooms across different zones
```

### Zone Instances
For multiplayer dungeons, implement zone instances:

```elixir
# New table: zone_instances
- zone_id (references zones)
- instance_number
- created_by_character_id
- expires_at
```

### Zone Access Control
Implement level requirements or quest prerequisites:

```elixir
# In Zone schema properties
properties: %{
  "required_level" => 10,
  "required_quest_ids" => [1, 2, 3],
  "faction_requirement" => "Alliance"
}
```

## Troubleshooting

### Issue: Rooms without zone_id

If you have rooms without a zone_id, run the backfill migration:

```bash
mix ecto.migrate
```

### Issue: Coordinate conflicts

If you get unique constraint errors, ensure you're including zone_id when creating rooms:

```elixir
# Always include zone_id
Map.create_room(%{
  zone_id: zone.id,  # Required!
  x_coordinate: 0,
  y_coordinate: 0,
  # ... other fields
})
```

### Issue: Legacy code breaks

Use the `get_room_by_coordinates_legacy/3` function for quick compatibility, then update code gradually to use zone-aware functions.

## Summary

The zone system is now fully implemented and ready to use. You can:

1. ✅ Create multiple independent zones/maps
2. ✅ Create rooms in different zones with the same coordinates
3. ✅ Query rooms by zone
4. ✅ Maintain backwards compatibility with existing rooms (in "Legacy Map" zone)
5. ✅ Organize your game world into logical areas

Next steps:
- Update LiveView code to use zone-aware functions
- Consider adding `current_zone_id` to character schema
- Create more zones using the seed file as a template
- Implement zone transition logic (portals, teleports, etc.)
