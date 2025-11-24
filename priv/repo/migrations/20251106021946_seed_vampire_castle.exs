defmodule Shard.Repo.Migrations.SeedVampireManor do
  use Ecto.Migration

  def change do
    execute(&seed_manor_up/0, &seed_manor_down/0)
  end

  defp seed_manor_up do
    alias Shard.Repo
    alias Shard.Map
    alias Shard.Map.Zone

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
      {-1, -4, "Master Chamber", "standard"},
      {-2, -4, "Cellar", "standard"},
      {-2, -5, "Cellar Doors", "treasure_room"}
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

    IO.puts("Created #{length(manor_rooms)} manor rooms")

    # Create doors for vampire's manor zone based on actual room coordinates
    manor_door_connections = [
      # Connect Courtyard NE (0,0) to Garden N (1,0)
      {{0, 0}, {1, 0}, "east"},
      # Connect Courtyard NE (0,0) to Courtyard SE (0,1)
      {{0, 0}, {0, 1}, "south"},
      # Connect Courtyard NE (0,0) to Courtyard NW (-1,0)
      {{0, 0}, {-1, 0}, "west"},
      # Connect Garden N (1,0) to Garden S (1,1)
      {{1, 0}, {1, 1}, "south"},
      # Connect Courtyard SE (0,1) to Courtyard SW (-1,1)
      {{0, 1}, {-1, 1}, "west"},
      # Connect Courtyard SW (-1,1) to Courtyard NW (-1,0)
      {{-1, 1}, {-1, 0}, "north"},
      # Connect Courtyard NW (-1,0) to Sewer Pipe Entrance (-2,0)
      {{-1, 0}, {-2, 0}, "west"},
      # Connect Sewer Pipe Entrance (-2,0) to Sewer Tunnel 1 (-3,0)
      {{-2, 0}, {-3, 0}, "west"},
      # Connect Sewer Tunnel 1 (-3,0) to Sewer Tunnel 2 (-3,1)
      {{-3, 0}, {-3, 1}, "south"},
      # Connect Sewer Tunnel 2 (-3,1) to Sewer Lair (-4,1)
      {{-3, 1}, {-4, 1}, "west"},
      # Connect Courtyard NE (0,0) to Manor Doorstep (0,-1)
      {{0, 0}, {0, -1}, "north"},
      # Connect Manor Doorstep (0,-1) to Manor Lobby SW (0,-2)
      {{0, -1}, {0, -2}, "north"},
      # Connect Manor Lobby SW (0,-2) to Library (-1,-2)
      {{0, -2}, {-1, -2}, "west"},
      # Connect Library (-1,-2) to Study (-1,-3)
      {{-1, -2}, {-1, -3}, "north"},
      # Connect Manor Lobby SW (0,-2) to Manor Lobby CW (0,-3)
      {{0, -2}, {0, -3}, "north"},
      # Connect Manor Lobby CW (0,-3) to Manor Lobby NW (0,-4)
      {{0, -3}, {0, -4}, "north"},
      # Connect Manor Lobby NW (0,-4) to Master Chamber (-1,-4)
      {{0, -4}, {-1, -4}, "west"},
      # Connect Master Chamber (-1,-4) to Cellar (-2,-4)
      {{-1, -4}, {-2, -4}, "west"},
      # Connect Cellar (-2,-4) to Cellar Doors (-2,-5)
      {{-2, -4}, {-2, -5}, "north"},
      # Connect Manor Lobby CW (0,-3) to Hallway W (1,-3)
      {{0, -3}, {1, -3}, "east"},
      # Connect Hallway W (1,-3) to Hallway E (2,-3)
      {{1, -3}, {2, -3}, "east"},
      # Connect Hallway E (2,-3) to Manor Lobby CE (3,-3)
      {{2, -3}, {3, -3}, "east"},
      # Connect Manor Lobby CE (3,-3) to Manor Lobby SE (3,-2)
      {{3, -3}, {3, -2}, "south"},
      # Connect Manor Lobby CE (3,-3) to Manor Lobby NE (3,-4)
      {{3, -3}, {3, -4}, "north"},
      # Connect Manor Lobby NE (3,-4) to Dining Hall W (4,-4)
      {{3, -4}, {4, -4}, "east"},
      # Connect Dining Hall W (4,-4) to Dining Hall E (5,-4)
      {{4, -4}, {5, -4}, "east"},
      # Connect Dining Hall E (5,-4) to Kitchen (5,-3)
      {{5, -4}, {5, -3}, "south"},
      # Connect Kitchen (5,-3) to Freezer (4,-3)
      {{5, -3}, {4, -3}, "west"}
    ]

    Enum.each(manor_door_connections, fn {{from_x, from_y}, {to_x, to_y}, direction} ->
      from_room =
        Enum.find(manor_rooms, &(&1.x_coordinate == from_x && &1.y_coordinate == from_y))

      to_room = Enum.find(manor_rooms, &(&1.x_coordinate == to_x && &1.y_coordinate == to_y))

      if from_room && to_room do
        # Determine if this door should be locked
        # Sewer entrance door
        # Main entrance door
        # Master chamber door
        # Study door
        # Library door
        # Cellar door
        is_locked =
          (from_x == 0 && from_y == -1 && to_x == 0 && to_y == -2) ||
            (from_x == -1 && from_y == 0 && to_x == -2 && to_y == 0) ||
            (from_x == 0 && from_y == -4 && to_x == -1 && to_y == -4) ||
            (from_x == -1 && from_y == -2 && to_x == -1 && to_y == -3) ||
            (from_x == 0 && from_y == -2 && to_x == -1 && to_y == -2) ||
            (from_x == -1 && from_y == -4 && to_x == -2 && to_y == -4)

        door_type = if is_locked, do: "locked_gate", else: "standard"

        key_required =
          cond do
            from_x == 0 && from_y == -1 && to_x == 0 && to_y == -2 -> "Manor Key"
            from_x == -1 && from_y == 0 && to_x == -2 && to_y == 0 -> "Rusty Sewer Key"
            from_x == 0 && from_y == -4 && to_x == -1 && to_y == -4 -> "Master Key"
            from_x == 0 && from_y == -2 && to_x == -1 && to_y == -2 -> "Library Key"
            from_x == -1 && from_y == -2 && to_x == -1 && to_y == -3 -> "Study Key"
            from_x == -1 && from_y == -4 && to_x == -2 && to_y == -4 -> "Cellar Key"
            true -> nil
          end

        # Create door (Map.create_door automatically creates the return door)
        case Map.create_door(%{
               from_room_id: from_room.id,
               to_room_id: to_room.id,
               direction: direction,
               door_type: door_type,
               is_locked: is_locked,
               key_required: key_required
             }) do
          {:ok, _door} ->
            :ok

          {:error, changeset} ->
            IO.puts("Failed to create door #{direction}: #{inspect(changeset.errors)}")
            raise "Door creation failed"
        end
      end
    end)

    IO.puts("Created doors for vampire manor zone")

    # Create sewage slime monster in the Sewer Lair
    sewer_lair = Enum.find(manor_rooms, &(&1.x_coordinate == -4 && &1.y_coordinate == 1))

    if sewer_lair do
      alias Shard.Monsters

      # Create the Slippers item if it doesn't exist
      slippers_item =
        case Repo.query("SELECT * FROM items WHERE name = $1", ["Slippers"]) do
          {:ok, %{rows: []}} ->
            {:ok, %{rows: [[item_id | _]]}} =
              Repo.query(
                "INSERT INTO items (name, description, item_type, rarity, value, stackable, equippable, equipment_slot, is_active, inserted_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id",
                [
                  "Slippers",
                  "Comfortable cloth slippers, slightly damp from the sewers.",
                  "material",
                  "common",
                  3,
                  false,
                  true,
                  "feet",
                  true,
                  DateTime.utc_now(),
                  DateTime.utc_now()
                ]
              )

            %{id: item_id}

          {:ok, %{rows: [[item_id | _]]}} ->
            %{id: item_id}
        end

      # Create the Manor Key item if it doesn't exist
      manor_key_item =
        case Repo.query("SELECT * FROM items WHERE name = $1", ["Manor Key"]) do
          {:ok, %{rows: []}} ->
            {:ok, %{rows: [[item_id | _]]}} =
              Repo.query(
                "INSERT INTO items (name, description, item_type, rarity, value, weight, equippable, equipment_slot, is_active, pickup, inserted_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id",
                [
                  "Manor Key",
                  "A heavy brass key with intricate engravings. It bears the crest of the vampire manor and unlocks the main entrance.",
                  "key",
                  "uncommon",
                  25,
                  0.2,
                  false,
                  nil,
                  true,
                  true,
                  DateTime.utc_now(),
                  DateTime.utc_now()
                ]
              )

            %{id: item_id}

          {:ok, %{rows: [[item_id | _]]}} ->
            %{id: item_id}
        end

      # Create the sewage slime monster with item drops
      {:ok, _slime} =
        Shard.Monsters.create_monster(%{
          name: "Sewage Slime",
          race: "Ooze",
          health: 20,
          max_health: 20,
          attack_damage: 2,
          xp_amount: 12,
          level: 2,
          description: "A disgusting blob of sewage and filth that has gained sentience.",
          location_id: sewer_lair.id,
          potential_loot_drops: %{
            "#{slippers_item.id}" => %{chance: 1.0, min_quantity: 1, max_quantity: 1}
          }
        })

      IO.puts("Successfully created Sewage Slime in Sewer Lair")
    else
      IO.puts("Warning: Sewer Lair room not found at (-4,1) in Vampire's Manor")
    end

    # Create possessed suit of armor monster in the Freezer
    freezer = Enum.find(manor_rooms, &(&1.x_coordinate == 4 && &1.y_coordinate == -3))

    if freezer do
      # Create the Chainmail items if they don't exist
      chainmail_items = [
        %{
          name: "Chainmail Helmet",
          description:
            "A helmet comprised of interlocking metal rings, cold to the touch and emanating dark energy.",
          item_type: "head",
          equipment_slot: "head"
        },
        %{
          name: "Chainmail Chestplate",
          description:
            "A suit of interlocking metal rings, cold to the touch and emanating dark energy.",
          item_type: "body",
          equipment_slot: "chest"
        },
        %{
          name: "Chainmail Leggings",
          description:
            "Leggings made of interlocking metal rings, cold to the touch and emanating dark energy.",
          item_type: "legs",
          equipment_slot: "legs"
        },
        %{
          name: "Chainmail Boots",
          description:
            "A pair of boots made up of interlocking metal rings, cold to the touch and emanating dark energy.",
          item_type: "feet",
          equipment_slot: "feet"
        },
        %{
          name: "Darkened Broadsword",
          description:
            "A blade, clearly discolored and dulled from constant use from its previous wielder.",
          item_type: "weapon",
          equipment_slot: "main_hand"
        }
      ]

      created_chainmail_items =
        Enum.map(chainmail_items, fn item_spec ->
          case Repo.query("SELECT id FROM items WHERE name = $1", [item_spec.name]) do
            {:ok, %{rows: []}} ->
              stats =
                if item_spec.name == "Darkened Broadsword", do: %{"attack_power" => 20}, else: %{}

              {:ok, %{rows: [[item_id]]}} =
                Repo.query(
                  "INSERT INTO items (name, description, item_type, rarity, value, stackable, equippable, equipment_slot, stats, is_active, inserted_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id",
                  [
                    item_spec.name,
                    item_spec.description,
                    item_spec.item_type,
                    "uncommon",
                    25,
                    false,
                    true,
                    item_spec.equipment_slot,
                    Jason.encode!(stats),
                    true,
                    DateTime.utc_now(),
                    DateTime.utc_now()
                  ]
                )

              %{id: item_id, name: item_spec.name}

            {:ok, %{rows: [[item_id]]}} ->
              %{id: item_id, name: item_spec.name}
          end
        end)

      # Create the Library Key item if it doesn't exist
      library_key_item =
        case Repo.query("SELECT * FROM items WHERE name = $1", ["Library Key"]) do
          {:ok, %{rows: []}} ->
            {:ok, %{rows: [[item_id | _]]}} =
              Repo.query(
                "INSERT INTO items (name, description, item_type, rarity, value, weight, equippable, equipment_slot, is_active, pickup, inserted_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id",
                [
                  "Library Key",
                  "A small, ornate key made of silver. It has the symbol of an open book etched into its head.",
                  "key",
                  "uncommon",
                  20,
                  0.1,
                  false,
                  nil,
                  true,
                  true,
                  DateTime.utc_now(),
                  DateTime.utc_now()
                ]
              )

            %{id: item_id}

          {:ok, %{rows: [[item_id | _]]}} ->
            %{id: item_id}
        end

      # Create the possessed suit of armor monster with multiple item drops
      loot_drops =
        created_chainmail_items
        |> Enum.map(fn item ->
          chance = if item.name == "Darkened Broadsword", do: 1.0, else: 0.3
          {"#{item.id}", %{chance: chance, min_quantity: 1, max_quantity: 1}}
        end)
        |> Enum.into(%{})
        |> Kernel.put_in([Access.key("#{library_key_item.id}")], %{
          chance: 1.0,
          min_quantity: 1,
          max_quantity: 1
        })

      {:ok, _armor} =
        Shard.Monsters.create_monster(%{
          name: "Possessed Suit of Armor",
          race: "Undead",
          health: 35,
          max_health: 35,
          attack_damage: 4,
          xp_amount: 20,
          level: 3,
          description:
            "An ancient suit of armor animated by dark magic, its empty helmet glowing with malevolent eyes.",
          location_id: freezer.id,
          potential_loot_drops: loot_drops
        })

      IO.puts("Successfully created Possessed Suit of Armor in Freezer")
    else
      IO.puts("Warning: Freezer room not found at (4,-3) in Vampire's Manor")
    end

    # Create The Count monster in the Master Chamber
    master_chamber = Enum.find(manor_rooms, &(&1.x_coordinate == -1 && &1.y_coordinate == -4))

    if master_chamber do
      # Create the Vampire Cloak item if it doesn't exist
      vampire_cloak_item =
        case Repo.query("SELECT * FROM items WHERE name = $1", ["Vampire Cloak"]) do
          {:ok, %{rows: []}} ->
            {:ok, %{rows: [[item_id | _]]}} =
              Repo.query(
                "INSERT INTO items (name, description, item_type, rarity, value, stackable, equippable, equipment_slot, is_active, inserted_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING id",
                [
                  "Vampire Cloak",
                  "A magnificent black cloak lined with crimson silk, radiating an aura of ancient power and nobility.",
                  "body",
                  "rare",
                  100,
                  false,
                  true,
                  "body",
                  true,
                  DateTime.utc_now(),
                  DateTime.utc_now()
                ]
              )

            %{id: item_id}

          {:ok, %{rows: [[item_id | _]]}} ->
            %{id: item_id}
        end

      # Create the Cellar Key item if it doesn't exist
      cellar_key_item =
        case Repo.query("SELECT * FROM items WHERE name = $1", ["Cellar Key"]) do
          {:ok, %{rows: []}} ->
            {:ok, %{rows: [[item_id | _]]}} =
              Repo.query(
                "INSERT INTO items (name, description, item_type, rarity, value, weight, equippable, equipment_slot, is_active, pickup, inserted_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12) RETURNING id",
                [
                  "Cellar Key",
                  "A heavy iron key stained with ancient blood. It bears the mark of the vampire lord and unlocks the deepest secrets of the manor.",
                  "key",
                  "rare",
                  50,
                  0.2,
                  false,
                  nil,
                  true,
                  true,
                  DateTime.utc_now(),
                  DateTime.utc_now()
                ]
              )

            %{id: item_id}

          {:ok, %{rows: [[item_id | _]]}} ->
            %{id: item_id}
        end

      # Create The Count monster with item drops
      {:ok, _count} =
        Shard.Monsters.create_monster(%{
          name: "The Count",
          race: "Vampire",
          health: 80,
          max_health: 80,
          attack_damage: 8,
          xp_amount: 50,
          level: 5,
          description:
            "The ancient master of this manor, a powerful vampire lord with centuries of dark knowledge and supernatural strength.",
          location_id: master_chamber.id,
          potential_loot_drops: %{
            "#{vampire_cloak_item.id}" => %{chance: 1.0, min_quantity: 1, max_quantity: 1},
            "#{cellar_key_item.id}" => %{chance: 1.0, min_quantity: 1, max_quantity: 1}
          }
        })

      IO.puts("Successfully created The Count in Master Chamber")
    else
      IO.puts("Warning: Master Chamber room not found at (-1,-4) in Vampire's Manor")
    end

    IO.puts("""

    ✓ Vampire's Manor successfully seeded!


    Created 1 zone:
    - Vampire Castle (4x4 grid, coordinates 0,0 to 3,3)
    """)
  end

  defp seed_manor_down do
    alias Shard.Repo
    alias Shard.Map.Zone

    IO.puts("Removing Vampire's Manor...")

    # Find and delete the sewage slime using raw SQL to avoid schema field issues
    result = Repo.query("SELECT id FROM monsters WHERE name = $1", ["Sewage Slime"])

    case result do
      {:ok, %{rows: [[slime_id]]}} ->
        Repo.query("DELETE FROM monsters WHERE id = $1", [slime_id])
        IO.puts("Deleted Sewage Slime")

      _ ->
        IO.puts("Sewage Slime not found")
    end

    # Find and delete the possessed suit of armor using raw SQL
    armor_result =
      Repo.query("SELECT id FROM monsters WHERE name = $1", ["Possessed Suit of Armor"])

    case armor_result do
      {:ok, %{rows: [[armor_id]]}} ->
        Repo.query("DELETE FROM monsters WHERE id = $1", [armor_id])
        IO.puts("Deleted Possessed Suit of Armor")

      _ ->
        IO.puts("Possessed Suit of Armor not found")
    end

    # Find and delete The Count using raw SQL
    count_result = Repo.query("SELECT id FROM monsters WHERE name = $1", ["The Count"])

    case count_result do
      {:ok, %{rows: [[count_id]]}} ->
        Repo.query("DELETE FROM monsters WHERE id = $1", [count_id])
        IO.puts("Deleted The Count")

      _ ->
        IO.puts("The Count not found")
    end

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
