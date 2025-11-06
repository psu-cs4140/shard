defmodule Shard.Repo.Migrations.SeedVampireManor do
  use Ecto.Migration

  def change do
    execute(&seed_manor_up/0, &seed_manor_down/0)
  end

  defp seed_manor_up do
    alias Shard.Repo
    alias Shard.Map
    alias Shard.Map.{Zone, Room, Door}

    IO.puts("Creating Vampire's Manor...")

    # Clean up any existing data first
    seed_manor_down()

    # Create Vampire Manor zone
    {:ok, manor_zone} =
      Map.create_zone(%{
        name: "Vampire's Manor",
        slug: "vampires-manor",
        description:
          "A dark and foreboding castle ruled by ancient vampires. Danger lurks in every shadow.",
        zone_type: "dungeon",
        min_level: 1,
        max_level: nil,
        is_public: true,
        is_active: true,
        display_order: 2,
        properties: %{
          "atmosphere" => "dark",
          "has_boss" => true,
          "recommended_party_size" => 4
        }
      })

    # Create Vampire Manor zone rooms using the specified coordinates

    manor_room_specs = [
      {0, 0, "Courtyard NE", "standard"},
      {-1, 0, "Courtyard NW", "standard"},
      {-1, 1, "Courtyard SW", "standard"},
      {0, 1, "Courtyard SE", "standard"},
      {0, -1, "Manor Doorstep", "standard"},
      {1, 0, "Garden N", "standard"},
      {1, 1, "Garden S", "standard"},
      {-2, 0, "Sewer Pipe Entrance", "standard"},
      {-3, 0, "Sewer Pipe Tunnel 1", "standard"},
      {-3, 1, "Sewer Pipe Tunnel 2", "standard"},
      {-4, 1, "Sewer Lair", "standard"},
      {0, -2, "Manor Lobby SW", "standard"},
      {0, -3, "Manor Lobby CW", "standard"},
      {0, -4, "Manor Lobby NW", "standard"},
      {-1, -2, "Library", "standard"},
      {1, -3, "Hallway W", "standard"},
      {2, -3, "Hallway E", "standard"},
      {3, -3, "Manor Lobby CE", "standard"},
      {3, -4, "Manor Lobby NE", "standard"},
      {3, -2, "Manor Lobby SE", "standard"},
      {4, -4, "Dining Hall W", "standard"},
      {5, -4, "Dining Hall E", "standard"},
      {5, -3, "Kitchen", "standard"},
      {4, -3, "Freezer", "standard"},
      {-1, -3, "Study", "standard"},
      {-1, -4, "Master Chambers", "standard"}
    ]

    manor_rooms =
      Enum.map(manor_room_specs, fn {x, y, room_name, room_type} ->
        case Map.create_room(%{
               name: "#{room_name} (Vampire's Manor)",
               description: "#{room_name} in the Vampire's Manor",
               zone_id: manor_zone.id,
               x_coordinate: x,
               y_coordinate: y,
               z_coordinate: 0,
               is_public: true,
               room_type: room_type
             }) do
          {:ok, room} ->
            room

          {:error, changeset} ->
            IO.puts("Failed to create room #{room_name}: #{inspect(changeset.errors)}")
            raise "Room creation failed for #{room_name}"
        end
      end)

    IO.puts("Created #{length(manor_rooms)} bone rooms")

    IO.puts("""

    ✓ Vampire Castle successfully seeded!

    Created 1 zone:
    - Vampire Castle (4x4 grid, coordinates 0,0 to 3,3)
    """)
  end

  defp seed_manor_down do
    alias Shard.Repo
    alias Shard.Map.{Zone, Room, Door}

    IO.puts("Removing Vampire's Manor...")

    # Delete zone by slug (this will cascade to rooms and doors)
    case Repo.get_by(Zone, slug: "vampires-manor") do
      nil ->
        IO.puts("Zone vampires-manor not found")

      zone ->
        Repo.delete!(zone)
        IO.puts("Deleted zone: #{zone.name}")
    end

    IO.puts("✓ Vampire Castle rollback completed!")
  end
end
