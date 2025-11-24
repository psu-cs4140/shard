# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule ShardWeb.UserLive.Movement do
  @moduledoc false
  use ShardWeb, :live_view
  alias Shard.Map, as: GameMap
  alias Shard.Repo
  alias Phoenix.PubSub
  import Ecto.Query

  alias Shard.Items.Item

  # Execute movement command and update game state
  def execute_movement(game_state, direction) do
    try do
      current_pos = game_state.player_position
      new_pos = calc_position(current_pos, direction, game_state)

      PubSub.unsubscribe(Shard.PubSub, posn_to_room_channel(current_pos))
      PubSub.subscribe(Shard.PubSub, posn_to_room_channel(new_pos))

      if new_pos == current_pos do
        {["You cannot move in that direction. There's no room or passage that way."], game_state}
      else
        # Update player position in database
        {new_x, new_y} = new_pos
        zone_id = game_state.character.current_zone_id || 1

        case GameMap.get_room_by_coordinates(zone_id, new_x, new_y, 0) do
          nil ->
            {["You cannot move in that direction. There's no room or passage that way."],
             game_state}

          room ->
            # Save position to database
            GameMap.update_player_position(game_state.character.id, zone_id, room)

            # Continue with existing movement logic
            execute_movement_with_room(game_state, direction, current_pos, new_pos, room)
        end
      end
    rescue
      _ ->
        {["You can't move that way."], game_state}
    end
  end

  defp execute_movement_with_room(game_state, direction, current_pos, new_pos, _room) do
    try do
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
          _ -> "unknown"
        end

      {_curr_x, _curr_y} = current_pos
      {new_x, new_y} = new_pos

      zone_id = game_state.character.current_zone_id || 1

      npcs_here = get_npcs_at_location(new_x, new_y, zone_id)
      items_here = get_items_at_location(new_x, new_y, zone_id)
      monsters = Enum.filter(game_state.monsters, fn m -> m[:position] == new_pos end)
      monster_count = Enum.count(monsters)

      response =
        ["You traversed #{direction_name}."] ++
          if length(npcs_here) > 0 do
            ["You see #{Enum.map_join(npcs_here, ", ", & &1.name)} here."]
          else
            []
          end ++
          if length(items_here) > 0 do
            Enum.map(items_here, fn item ->
              "You see a #{item.name || "unknown item"} on the ground."
            end)
          else
            []
          end ++
          cond do
            monster_count == 1 ->
              ["There is a #{Enum.at(monsters, 0)[:name]} here! It prepares to attack."]

            monster_count > 1 ->
              names = Enum.map_join(monsters, ", ", fn m -> "a " <> to_string(m[:name]) end)

              [
                "There are #{monster_count} monsters! The monsters include #{names}.",
                "They prepare to attack."
              ]

            true ->
              []
          end

      updated_game_state = %{game_state | player_position: new_pos}
      {combat_msgs, updated_game_state} = Shard.Combat.start_combat(updated_game_state)
      final_response = response ++ combat_msgs

      {final_response, updated_game_state}
    rescue
      _ ->
        {["You can't move that way."], game_state}
    end
  end

  # To calculate new player position on map
  def calc_position(curr_position, key, game_state) do
    new_position =
      case key do
        "ArrowUp" -> {elem(curr_position, 0), elem(curr_position, 1) - 1}
        "ArrowDown" -> {elem(curr_position, 0), elem(curr_position, 1) + 1}
        "ArrowRight" -> {elem(curr_position, 0) + 1, elem(curr_position, 1)}
        "ArrowLeft" -> {elem(curr_position, 0) - 1, elem(curr_position, 1)}
        "northeast" -> {elem(curr_position, 0) + 1, elem(curr_position, 1) + 1}
        "southeast" -> {elem(curr_position, 0) + 1, elem(curr_position, 1) - 1}
        "northwest" -> {elem(curr_position, 0) - 1, elem(curr_position, 1) + 1}
        "southwest" -> {elem(curr_position, 0) - 1, elem(curr_position, 1) - 1}
        _ -> curr_position
      end

    if valid_movement(curr_position, new_position, key, game_state) do
      new_position
    else
      curr_position
    end
  end

  defp valid_movement(current_pos, new_pos, direction, game_state) do
    {curr_x, curr_y} = current_pos
    {new_x, new_y} = new_pos

    zone_id = game_state.character.current_zone_id || 1

    current_room =
      GameMap.get_room_by_coordinates(zone_id, curr_x, curr_y, 0)

    case current_room do
      nil ->
        false

      room ->
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
              false

            door ->
              cond do
                door.is_locked ->
                  false

                door.door_type == "secret" ->
                  false

                true ->
                  target_room = GameMap.get_room!(door.to_room_id)

                  target_room.x_coordinate == new_x and
                    target_room.y_coordinate == new_y
              end
          end
        else
          false
        end
    end
  end

  def get_available_exits(x, y, room, game_state) do
    exits = []

    exits =
      if room do
        doors =
          from(d in GameMap.Door, where: d.from_room_id == ^room.id)
          |> Repo.all()

        door_exits =
          Enum.map(doors, fn door ->
            cond do
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
        test_pos = calc_position({x, y}, direction_to_key(direction), game_state)

        test_pos != {x, y} and
          valid_movement({x, y}, test_pos, direction_to_key(direction), game_state)
      end)

    (exits ++ tutorial_exits)
    |> Enum.uniq()
    |> Enum.sort()
  end

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

  def compute_available_exits({x, y}, game_state) do
    zone_id = game_state.character.current_zone_id || 1

    case GameMap.get_room_by_coordinates(zone_id, x, y, 0) do
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

  defp get_npcs_at_location(_x, _y, _zone_id) do
    []
  end

  defp get_items_at_location(x, y, _zone_id) do
    alias Shard.Items.RoomItem
    location_string = "#{x},#{y},0"

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

    direct_items =
      from(i in Item,
        where:
          i.location == ^location_string and
            (is_nil(i.is_active) or i.is_active == true),
        select: %{
          name: i.name,
          description: i.description,
          item_type: i.item_type,
          quantity: 1
        }
      )
      |> Repo.all()

    all_items = room_items ++ direct_items
    all_items |> Enum.uniq_by(& &1.name)
  end
end
