defmodule ShardWeb.UserLive.Movement do
  use ShardWeb, :live_view
  alias Shard.Map, as: GameMap
  alias Shard.Repo
  alias Phoenix.PubSub
  import Ecto.Query
  import ShardWeb.UserLive.MapHelpers
  alias Shard.Items.Item

  # Execute movement command and update game state
  def execute_movement(game_state, direction) do
    current_pos = game_state.player_position
    new_pos = calc_position(current_pos, direction, game_state.map_data)

    PubSub.unsubscribe(
      Shard.PubSub,
      posn_to_room_channel(current_pos)
    )

    PubSub.subscribe(
      Shard.PubSub,
      posn_to_room_channel(new_pos)
    )

    if new_pos == current_pos do
      response = ["You cannot move in that direction. There's no room or passage that way."]
      {response, game_state}
    else
      direction_name =
        case direction do
          "ArrowUp" -> "north"
          "ArrowDown" -> "south"
          "ArrowRight" -> "east"
          "ArrowLeft" -> "west"
          "northeast" -> "northeast"
          "southeast" -> "southeast"
          "northwest" -> "northwest"
          "southwest" -> "southwest"
        end

      # Get current and destination rooms for dungeon completion check
      {curr_x, curr_y} = current_pos
      {new_x, new_y} = new_pos
      current_room = GameMap.get_room_by_coordinates(curr_x, curr_y)
      destination_room = GameMap.get_room_by_coordinates(new_x, new_y)

      # Check for dungeon completion
      completion_result = GameMap.check_dungeon_completion(current_room, destination_room)

      # Check for NPCs at the new location
      npcs_here = get_npcs_at_location(new_x, new_y, game_state.map_id)

      # Check for items at the new location
      items_here = get_items_at_location(new_x, new_y, game_state.map_id)

      response = ["You traversed #{direction_name}."]

      # Don't add dungeon completion message to response - will be handled as popup

      # Add NPC presence notification if any NPCs are at the new location
      response =
        response ++
          if length(npcs_here) > 0 do
            npc_names = Enum.map_join(npcs_here, ", ", & &1.name)
            # above is more efficent
            # npc_names = Enum.map(npcs_here, & &1.name) |> Enum.join(", ")
            ["You see #{npc_names} here."]
          else
            []
          end

      # Add item descriptions if any are present
      response =
        response ++
          if length(items_here) > 0 do
            item_descriptions =
              Enum.map(items_here, fn item ->
                item_name = Map.get(item, :name) || "Unknown Item"
                "You see a #{item_name} on ground"
              end)

            item_descriptions
          else
            []
          end

      # To see if there are monsters
      monsters = Enum.filter(game_state.monsters, fn value -> value[:position] == new_pos end)
      monster_count = Enum.count(monsters)

      response =
        response ++
          case monster_count do
            0 ->
              []

            1 ->
              ["There is a " <> Enum.at(monsters, 0)[:name] <> "! It prepares to attack."]

            _ ->
              [
                "There are " <>
                  to_string(monster_count) <>
                  " monsters! The monsters include " <>
                  Enum.map_join(monsters, ", ", fn monster ->
                    "a " <> to_string(monster[:name])
                  end) <> ".",
                "They prepare to attack."
              ]
          end

      updated_game_state = %{game_state | player_position: new_pos}

      # Check for combat
      {combat_messages, updated_game_state} =
        Shard.Combat.start_combat(updated_game_state)

      # Return completion result separately for popup handling
      final_response = response ++ combat_messages

      case completion_result do
        {:completed, message} ->
          {final_response, updated_game_state, {:show_completion_popup, message}}

        :no_completion ->
          {final_response, updated_game_state, :no_popup}
      end
    end
  end

  # To calculate new player position on map
  def calc_position(curr_position, key, _map_data) do
    new_position =
      case key do
        # Align with DB: north increases y, south decreases y
        "ArrowUp" ->
          {elem(curr_position, 0), elem(curr_position, 1) - 1}

        "ArrowDown" ->
          {elem(curr_position, 0), elem(curr_position, 1) + 1}

        "ArrowRight" ->
          {elem(curr_position, 0) + 1, elem(curr_position, 1)}

        "ArrowLeft" ->
          {elem(curr_position, 0) - 1, elem(curr_position, 1)}

        "northeast" ->
          {elem(curr_position, 0) + 1, elem(curr_position, 1) + 1}

        "southeast" ->
          {elem(curr_position, 0) + 1, elem(curr_position, 1) - 1}

        "northwest" ->
          {elem(curr_position, 0) - 1, elem(curr_position, 1) + 1}

        "southwest" ->
          {elem(curr_position, 0) - 1, elem(curr_position, 1) - 1}

        _other ->
          curr_position
      end

    # Check if the movement is valid (room exists or door connection exists)
    if valid_movement(curr_position, new_position, key) do
      new_position
    else
      curr_position
    end
  end

  # Helper function to check if a position is valid (has a room or door connection)
  defp valid_position({x, y}, _map_data) do
    # Check if there's a room at this position
    case GameMap.get_room_by_coordinates(x, y) do
      # No room exists at this position
      nil -> false
      # Room exists, movement is valid
      _room -> true
    end
  end

  # Helper function to check if movement is valid via door connection
  defp valid_movement(current_pos, new_pos, direction) do
    {curr_x, curr_y} = current_pos
    {new_x, new_y} = new_pos

    # First check if there's a room at the current position
    current_room = GameMap.get_room_by_coordinates(curr_x, curr_y)

    case current_room do
      # No current room, can't move
      nil ->
        false

      room ->
        # Check if there's a door in the specified direction from current room
        direction_str =
          case direction do
            "ArrowUp" -> "north"
            "ArrowDown" -> "south"
            "ArrowRight" -> "east"
            "ArrowLeft" -> "west"
            "northeast" -> "northeast"
            "southeast" -> "southeast"
            "northwest" -> "northwest"
            "southwest" -> "southwest"
            _ -> nil
          end

        if direction_str do
          door = GameMap.get_door_in_direction(room.id, direction_str)

          case door do
            nil ->
              # No door, check if target position has a room
              valid_position(new_pos, nil)

            door ->
              # Check door accessibility based on type and status
              cond do
                door.is_locked ->
                  IO.puts("Movement blocked: The #{door.door_type} is locked")
                  false

                door.door_type == "secret" ->
                  IO.puts("Movement blocked: Secret passage not discovered")
                  false

                true ->
                  # Door exists and is accessible, check if it leads to target position
                  target_room = GameMap.get_room!(door.to_room_id)

                  if target_room.x_coordinate == new_x and target_room.y_coordinate == new_y do
                    IO.puts("Moving through #{door.door_type} door")
                    true
                  else
                    false
                  end
              end
          end
        else
          false
        end
    end
  end

  # Helper function to get available exits from current position
  def get_available_exits(x, y, room) do
    exits = []

    # If we have a room, check for doors
    exits =
      if room do
        # Get doors from this room using Ecto query since the function might not exist
        doors =
          from(d in GameMap.Door, where: d.from_room_id == ^room.id)
          |> Repo.all()

        door_exits =
          Enum.map(doors, fn door ->
            cond do
              # Hidden secret doors
              door.door_type == "secret" and door.is_locked -> nil
              door.is_locked -> "#{door.direction} (locked)"
              door.key_required && door.key_required != "" -> "#{door.direction} (key required)"
              true -> door.direction
            end
          end)
          |> Enum.filter(&(&1 != nil))

        exits ++ door_exits
      else
        exits
      end

    # For tutorial terrain, also check basic movement possibilities
    basic_directions = [
      "north",
      "south",
      "east",
      "west",
      "northeast",
      "southeast",
      "northwest",
      "southwest"
    ]

    tutorial_exits =
      Enum.filter(basic_directions, fn direction ->
        test_pos = calc_position({x, y}, direction_to_key(direction), nil)
        test_pos != {x, y} and valid_movement({x, y}, test_pos, direction_to_key(direction))
      end)

    (exits ++ tutorial_exits)
    |> Enum.uniq()
    |> Enum.sort()
  end

  # Helper function to convert direction string to key for calc_position
  def direction_to_key(direction) do
    case direction do
      "north" -> "ArrowUp"
      "south" -> "ArrowDown"
      "east" -> "ArrowRight"
      "west" -> "ArrowLeft"
      "northeast" -> "northeast"
      "southeast" -> "southeast"
      "northwest" -> "northwest"
      "southwest" -> "southwest"
      _ -> direction
    end
  end

  # (B) Given the player’s current grid position {x, y}, compute which exits (doors) exist
  def compute_available_exits({x, y}) do
    case GameMap.get_room_by_coordinates(x, y) do
      nil ->
        []

      room ->
        doors = GameMap.get_doors_from_room(room.id)

        valid_dirs =
          MapSet.new([
            "north",
            "south",
            "east",
            "west",
            "northeast",
            "northwest",
            "southeast",
            "southwest"
          ])

        doors
        |> Enum.filter(fn d -> d.direction in valid_dirs end)
        |> Enum.map(fn d -> %{direction: d.direction, door: d} end)
    end
  end

  def posn_to_room_channel({xx, yy}) do
    "room:#{xx},#{yy}"
  end

  # Get items at a specific location
  defp get_items_at_location(x, y, map_id) do
    alias Shard.Items.RoomItem
    location_string = "#{x},#{y},0"

    # Get items from RoomItem table (items placed in world)
    room_items =
      from(ri in RoomItem,
        where: ri.location == ^location_string,
        join: i in Item,
        on: ri.item_id == i.id,
        where: is_nil(i.is_active) or i.is_active == true,
        select: %{
          name: i.name,
          description: i.description,
          item_type: i.item_type,
          quantity: ri.quantity
        }
      )
      |> Repo.all()

    # Also check for items directly in Item table with matching location and map
    direct_items =
      from(i in Item,
        where:
          i.location == ^location_string and
            (i.map == ^map_id or is_nil(i.map)) and
            (is_nil(i.is_active) or i.is_active == true),
        select: %{
          name: i.name,
          description: i.description,
          item_type: i.item_type,
          quantity: 1
        }
      )
      |> Repo.all()

    # Combine both results and remove duplicates based on name
    all_items = room_items ++ direct_items
    all_items |> Enum.uniq_by(& &1.name)
  end
end
