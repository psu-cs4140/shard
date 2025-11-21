defmodule ShardWeb.AdminLive.NpcHelpers do
  alias Shard.Repo
  alias Shard.Npcs

  def ensure_tutorial_npcs_exist do
    # Ensure required rooms exist first
    ensure_bone_zone_rooms_exist()
    
    tutorial_npcs = [
      %{
        name: "Goldie",
        description:
          "A friendly golden retriever with a wagging tail and bright, intelligent eyes. Goldie loves to greet adventurers and seems to understand more than most dogs.",
        npc_type: "friendly",
        level: 1,
        health: 50,
        max_health: 50,
        mana: 0,
        max_mana: 0,
        strength: 5,
        dexterity: 8,
        intelligence: 6,
        constitution: 7,
        experience_reward: 0,
        gold_reward: 0,
        faction: "neutral",
        aggression_level: 0,
        movement_pattern: "random",
        is_active: true,
        dialogue: "Woof! *wags tail enthusiastically*",
        location_x: 0,
        location_y: 0,
        location_z: 0
      },
      %{
        name: "Elder Thorne",
        description:
          "An ancient wizard with a long white beard and twinkling eyes. His robes shimmer with magical energy, and he carries a gnarled staff topped with a glowing crystal.",
        npc_type: "quest_giver",
        level: 50,
        health: 200,
        max_health: 200,
        mana: 500,
        max_mana: 500,
        strength: 8,
        dexterity: 6,
        intelligence: 20,
        constitution: 12,
        experience_reward: 0,
        gold_reward: 0,
        faction: "neutral",
        aggression_level: 0,
        movement_pattern: "stationary",
        is_active: true,
        dialogue:
          "Welcome, young adventurer! I have been expecting you. There are many mysteries in this realm that need solving.",
        location_x: 0,
        location_y: 1,
        location_z: 0
      },
      %{
        name: "Merchant Pip",
        description:
          "A cheerful halfling merchant with a round belly and a wide smile. His cart is filled with various goods, potions, and trinkets that catch the light.",
        npc_type: "merchant",
        level: 10,
        health: 80,
        max_health: 80,
        mana: 50,
        max_mana: 50,
        strength: 6,
        dexterity: 12,
        intelligence: 14,
        constitution: 10,
        experience_reward: 0,
        gold_reward: 0,
        faction: "neutral",
        aggression_level: 0,
        movement_pattern: "stationary",
        is_active: true,
        dialogue:
          "Welcome to Pip's Traveling Emporium! I've got the finest wares this side of the mountains. What can I get for you today?",
        location_x: -2,
        location_y: 1,
        location_z: 0
      },
      %{
        name: "Training Dummy",
        description:
          "A sturdy wooden training dummy wrapped in straw and leather. It bears the marks of countless practice sessions and stands ready for combat training.",
        npc_type: "neutral",
        level: 1,
        health: 100,
        max_health: 100,
        mana: 0,
        max_mana: 0,
        strength: 1,
        dexterity: 1,
        intelligence: 1,
        constitution: 15,
        experience_reward: 5,
        gold_reward: 0,
        faction: "neutral",
        aggression_level: 0,
        movement_pattern: "stationary",
        is_active: true,
        dialogue: "*The training dummy stands silently, ready to absorb your attacks*",
        location_x: 1,
        location_y: -1,
        location_z: 0
      },
      %{
        name: "Tombguard",
        description:
          "An ancient sentinel clad in tarnished armor, standing vigil over the tomb's entrance. His hollow eyes burn with an otherworldly light, and his presence commands both respect and unease.",
        npc_type: "quest_giver",
        level: 25,
        health: 300,
        max_health: 300,
        mana: 150,
        max_mana: 150,
        strength: 15,
        dexterity: 8,
        intelligence: 12,
        constitution: 18,
        experience_reward: 0,
        gold_reward: 0,
        faction: "neutral",
        aggression_level: 0,
        movement_pattern: "stationary",
        is_active: true,
        dialogue: "Before you face the Bone Zone beyond, you must arm yourself. A blade once rested beside your coffin — your blade — but the lesser dead have claimed it for themselves. They skulk in the lower chambers, drawn to its lingering power.",
        location_x: 0,
        location_y: 3,
        location_z: 0
      }
    ]

    Enum.each(tutorial_npcs, &ensure_npc_exists/1)
  end

  defp ensure_npc_exists(npc_params) do
    case Npcs.get_npc_by_name(npc_params.name) do
      nil ->
        create_new_npc(npc_params)

      existing_npc ->
        ensure_npc_location(existing_npc, npc_params)
    end
  end

  defp create_new_npc(npc_params) do
    case Npcs.create_npc(npc_params) do
      {:ok, _npc} -> :ok
      {:error, _changeset} -> :error
    end
  end

  defp ensure_npc_location(existing_npc, npc_params) do
    expected_x = npc_params.location_x
    expected_y = npc_params.location_y
    expected_z = npc_params.location_z

    if location_needs_update?(existing_npc, expected_x, expected_y, expected_z) do
      update_npc_location(existing_npc, expected_x, expected_y, expected_z)
    end

    :ok
  end

  defp location_needs_update?(npc, expected_x, expected_y, expected_z) do
    npc.location_x != expected_x or
      npc.location_y != expected_y or
      npc.location_z != expected_z
  end

  defp update_npc_location(npc, x, y, z) do
    npc
    |> Ecto.Changeset.change(%{
      location_x: x,
      location_y: y,
      location_z: z
    })
    |> Repo.update()
  end

  # Ensure the Bone Zone rooms exist for proper navigation
  defp ensure_bone_zone_rooms_exist do
    alias Shard.Map, as: GameMap
    
    IO.puts("Starting Bone Zone room creation process...")
    
    # Define the rooms that should exist in the Bone Zone (zone_id: 1)
    bone_zone_rooms = [
      # Existing rooms that should be there
      %{zone_id: 1, x_coordinate: 2, y_coordinate: 4, z_coordinate: 0, name: "Bone Zone - Southern Chamber", description: "A dark chamber filled with ancient bones and the whispers of the dead."},
      %{zone_id: 1, x_coordinate: 2, y_coordinate: 3, z_coordinate: 0, name: "Bone Zone - Central Passage", description: "A narrow passage between chambers, bones crunch underfoot."},
      %{zone_id: 1, x_coordinate: 2, y_coordinate: 2, z_coordinate: 0, name: "Bone Zone - Northern Passage", description: "The passage continues north, growing darker and more ominous."},
      %{zone_id: 1, x_coordinate: 2, y_coordinate: 1, z_coordinate: 0, name: "Bone Zone - Upper Chamber", description: "A large chamber with high ceilings, filled with the echoes of ancient battles."},
      %{zone_id: 1, x_coordinate: 2, y_coordinate: 0, z_coordinate: 0, name: "Bone Zone - Northernmost Chamber", description: "The final chamber to the north, where shadows dance in the dim light."}
    ]

    Enum.each(bone_zone_rooms, &ensure_room_exists/1)
    
    # Create doors between the rooms for proper navigation
    ensure_bone_zone_doors_exist()
    
    IO.puts("Finished Bone Zone room creation process.")
  end

  defp ensure_room_exists(room_params) do
    alias Shard.Map, as: GameMap
    
    x = room_params.x_coordinate
    y = room_params.y_coordinate
    z = room_params.z_coordinate
    
    case GameMap.get_room_by_coordinates(room_params.zone_id, x, y, z) do
      nil ->
        IO.puts("Creating room at (#{x}, #{y}, #{z}): #{room_params.name}")
        create_new_room(room_params)
      existing_room ->
        IO.puts("Room already exists at (#{x}, #{y}, #{z}): #{existing_room.name}")
        :ok
    end
  end

  defp create_new_room(room_params) do
    alias Shard.Map, as: GameMap
    
    case GameMap.create_room(room_params) do
      {:ok, room} -> 
        IO.puts("Successfully created room: #{room.name} at (#{room.x_coordinate}, #{room.y_coordinate}, #{room.z_coordinate})")
        :ok
      {:error, changeset} -> 
        IO.puts("Failed to create room: #{inspect(changeset.errors)}")
        :error
    end
  end

  defp ensure_bone_zone_doors_exist do
    alias Shard.Map, as: GameMap
    
    # Define door connections for the Bone Zone vertical path
    door_connections = [
      # From (2,4) to (2,3) - north/south
      {1, 2, 4, 0, 2, 3, 0, "north", "south"},
      # From (2,3) to (2,2) - north/south  
      {1, 2, 3, 0, 2, 2, 0, "north", "south"},
      # From (2,2) to (2,1) - north/south
      {1, 2, 2, 0, 2, 1, 0, "north", "south"},
      # From (2,1) to (2,0) - north/south
      {1, 2, 1, 0, 2, 0, 0, "north", "south"}
    ]

    Enum.each(door_connections, &ensure_door_connection_exists/1)
  end

  defp ensure_door_connection_exists({zone_id, from_x, from_y, from_z, to_x, to_y, to_z, direction, opposite_direction}) do
    alias Shard.Map, as: GameMap
    
    from_room = GameMap.get_room_by_coordinates(zone_id, from_x, from_y, from_z)
    to_room = GameMap.get_room_by_coordinates(zone_id, to_x, to_y, to_z)

    if from_room && to_room do
      # Check if door already exists
      existing_door = GameMap.get_door_in_direction(from_room.id, direction)
      
      unless existing_door do
        # Create the door from -> to
        case GameMap.create_door(%{
          from_room_id: from_room.id,
          to_room_id: to_room.id,
          direction: direction,
          is_locked: false,
          is_hidden: false
        }) do
          {:ok, _door} ->
            IO.puts("Created door from (#{from_x}, #{from_y}) #{direction} to (#{to_x}, #{to_y})")
          {:error, changeset} ->
            IO.puts("Failed to create door: #{inspect(changeset.errors)}")
        end
      end

      # Check if return door already exists
      existing_return_door = GameMap.get_door_in_direction(to_room.id, opposite_direction)
      
      unless existing_return_door do
        # Create the return door to -> from
        case GameMap.create_door(%{
          from_room_id: to_room.id,
          to_room_id: from_room.id,
          direction: opposite_direction,
          is_locked: false,
          is_hidden: false
        }) do
          {:ok, _door} ->
            IO.puts("Created return door from (#{to_x}, #{to_y}) #{opposite_direction} to (#{from_x}, #{from_y})")
          {:error, changeset} ->
            IO.puts("Failed to create return door: #{inspect(changeset.errors)}")
        end
      end
    else
      IO.puts("Cannot create door connection: from_room=#{inspect(from_room)}, to_room=#{inspect(to_room)}")
    end
  end
end
