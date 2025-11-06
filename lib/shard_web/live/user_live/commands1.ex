# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule ShardWeb.UserLive.Commands1 do
  @moduledoc false
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.QuestHandlers
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.Commands2
  import ShardWeb.UserLive.Commands3

  import ShardWeb.UserLive.CommandParsers,
    except: [
      parse_talk_command: 1,
      parse_quest_command: 1,
      parse_pickup_command: 1,
      parse_deliver_quest_command: 1,
      execute_pickup_command: 2
    ]

  alias Shard.Map, as: GameMap
  alias Shard.Items.Item
  alias Shard.Items.AdminStick
  alias Shard.Repo
  import Ecto.Query

  # Process terminal commands
  def process_command(command, game_state) do
    downcased_command = String.downcase(command)

    cond do
      downcased_command == "help" ->
        response = [
          "Available commands:",
          "  look - Examine your surroundings",
          "  attack - Attack an enemy in the room (if in combat)",
          "  flee - Attempt to flee from combat",
          "  stats - Show your character stats",
          "  position - Show your current position",
          "  inventory - Show your inventory (coming soon)",
          "  pickup \"item_name\" - Pick up an item from the room",
          "  npc - Show descriptions of NPCs in this room",
          "  talk \"npc_name\" - Talk to a specific NPC",
          "  quest \"npc_name\" - Get quest from a specific NPC",
          "  accept - Accept a quest offer",
          "  deny - Deny a quest offer",
          "  deliver_quest \"npc_name\" - Deliver completed quest to NPC",
          "  poke \"character_name\" - Poke another player",
          "  north/south/east/west - Move in cardinal directions",
          "  northeast/southeast/northwest/southwest - Move diagonally",
          "  Shortcuts: n/s/e/w/ne/se/nw/sw",
          "  unlock [direction] with [item_name] - Unlock a door using an item",
          "  create room [direction] - Create a new room in the specified direction (admin only)",
          "  delete room [direction] - Delete the room in the specified direction (admin only)",
          "  create door [direction] - Create a door in the specified direction (admin only)",
          "  delete door [direction] - Delete the door in the specified direction (admin only)",
          "  help - Show this help message"
        ]

        {response, game_state}

      downcased_command == "attack" ->
        {x, y} = game_state.player_position

        # Check if there are monsters at current location
        monsters_here =
          Enum.filter(game_state.monsters, fn monster ->
            monster[:position] == {x, y} && monster[:is_alive] != false
          end)

        if Enum.empty?(monsters_here) do
          {["There are no monsters here to attack."], game_state}
        else
          # Start combat if not already in combat
          updated_game_state =
            if Shard.Combat.in_combat?(game_state) do
              game_state
            else
              %{game_state | combat: true}
            end

          Shard.Combat.execute_action(updated_game_state, "attack")
        end

      downcased_command == "flee" ->
        if Shard.Combat.in_combat?(game_state) do
          Shard.Combat.execute_action(game_state, "flee")
        else
          {["There is nothing to flee from..."], game_state}
        end

      downcased_command == "look" ->
        {x, y} = game_state.player_position

        # Get room from database
        room = GameMap.get_room_by_coordinates(game_state.character.current_zone_id, x, y, 0)
        # Build room description - always use predetermined descriptions for tutorial terrain
        room_description =
          if game_state.map_id == "tutorial_terrain" do
            # Provide tutorial-specific descriptions based on coordinates
            case {x, y} do
              {0, 0} ->
                "Tutorial Starting Chamber\nYou are in a small stone chamber with rough-hewn walls. Ancient torches mounted on iron brackets cast flickering light across the weathered stones. This appears to be the beginning of your adventure. You can see worn footprints in the dust, suggesting others have passed this way before."

              {1, 0} ->
                "Eastern Alcove\nA narrow alcove extends eastward from the starting chamber. The walls here are carved with simple symbols that seem to glow faintly in the torchlight. The air carries a hint of something ancient and mysterious."

              {0, 1} ->
                "Southern Passage\nA short passage leads south from the starting chamber. The stone floor is worn smooth by countless footsteps. Moisture drips steadily from somewhere in the darkness ahead."

              {1, 1} ->
                "Corner Junction\nYou stand at a junction where two passages meet. The walls here show signs of careful construction, with fitted stones and mortar still holding strong after unknown years. A cool breeze flows through the intersection."

              {5, 5} ->
                "Central Treasure Chamber\nYou stand in a magnificent circular chamber with a high vaulted ceiling. Ornate pillars support graceful arches, and in the center sits an elaborate treasure chest made of dark wood bound with brass. The chest gleams with an inner light, and precious gems are scattered around its base."

              {2, 2} ->
                "Training Grounds\nThis rectangular chamber appears to have been used for combat training. Wooden practice dummies stand against the walls, and the floor is marked with scuff marks from countless sparring sessions. Weapon racks line the eastern wall."

              {3, 3} ->
                "Meditation Garden\nA peaceful underground garden with carefully tended moss growing in geometric patterns on the floor. A small fountain in the center provides the gentle sound of flowing water. The air here feels calm and restorative."

              {4, 4} ->
                "Library Ruins\nThe remains of what was once a grand library. Broken shelves line the walls, and scattered parchments lie across the floor. A few intact books rest on a reading table, their pages yellowed with age but still legible."

              {6, 6} ->
                "Armory\nA well-organized armory with weapons and armor displayed on stands and hanging from hooks. Most of the equipment shows signs of age, but some pieces still gleam with careful maintenance. A forge in the corner appears recently used."

              {7, 7} ->
                "Crystal Cavern\nA natural cavern where the walls are embedded with glowing crystals that provide a soft, blue-white light. The crystals hum with a barely audible resonance, and the air shimmers with magical energy."

              {8, 8} ->
                "Underground Lake\nYou stand on the shore of a vast underground lake. The water is crystal clear and so still it perfectly reflects the cavern ceiling above. Strange fish with luminescent scales can be seen swimming in the depths."

              {9, 9} ->
                "Ancient Shrine\nA small shrine dedicated to forgotten deities. Stone statues stand in alcoves around the room, their faces worn smooth by time. An altar in the center holds offerings left by previous visitors - coins, flowers, and small trinkets."

              _ ->
                # Check tile type for other positions
                if y >= 0 and y < length(game_state.map_data) do
                  row = Enum.at(game_state.map_data, y)

                  if x >= 0 and x < length(row) do
                    tile = Enum.at(row, x)

                    case tile do
                      0 ->
                        "Solid Stone Wall\nYou face an impenetrable wall of fitted stone blocks. The craftsmanship is excellent, with no gaps or weaknesses visible. There's no passage here."

                      1 ->
                        "Stone Corridor\nYou are in a well-constructed stone corridor. The walls are made of carefully fitted blocks, and the floor is worn smooth by the passage of many feet over the years. Torch brackets line the walls, though most are empty. The air is cool and carries the faint scent of old stone and distant moisture."

                      2 ->
                        "Underground Pool\nYou stand beside a clear underground pool fed by a natural spring. The water is deep and perfectly still, reflecting the ceiling above like a mirror. Small ripples occasionally disturb the surface as drops fall from stalactites overhead. The air here is humid and fresh."

                      3 ->
                        "Treasure Alcove\nA small alcove has been carved into the stone wall here. The niche shows signs of having once held something valuable - there are mounting brackets and a small pedestal. Scratches on the floor suggest heavy objects were once moved in and out of this space."

                      _ ->
                        "Mystical Chamber\nYou are in a chamber that defies easy description. The very air seems to shimmer with arcane energy, and the walls appear to shift slightly when you're not looking directly at them. Strange symbols carved into the stone pulse with a faint, otherworldly light."
                    end
                  else
                    "The Void\nYou have somehow moved beyond the boundaries of the known world. Reality becomes uncertain here, and the very ground beneath your feet feels insubstantial. Wisps of strange energy drift through the air, and distant sounds echo from nowhere."
                  end
                else
                  "The Void\nYou have somehow moved beyond the boundaries of the known world. Reality becomes uncertain here, and the very ground beneath your feet feels insubstantial. Wisps of strange energy drift through the air, and distant sounds echo from nowhere."
                end
            end
          else
            # For non-tutorial maps, use room data from database if available
            case room do
              nil ->
                "Empty Space\nYou are in an empty area with no defined room. The ground beneath your feet feels uncertain, as if this space exists between the cracks of reality."

              room ->
                room_title = room.name || "Unnamed Room"

                room_desc =
                  room.description ||
                    "A mysterious room with no particular features. The walls are bare stone, and the air is still and quiet."

                "#{room_title}\n#{room_desc}"
            end
          end

        # Check for NPCs at current location
        npcs_here = get_npcs_at_location(x, y, game_state.character.current_zone_id)

        # Check for items at current location
        items_here = get_items_at_location(x, y, game_state.character.current_zone_id)

        description_lines = [room_description]

        # Add NPC descriptions if any are present
        description_lines =
          if length(npcs_here) > 0 do
            # Empty line for spacing
            updated_lines = description_lines ++ [""]

            # Add each NPC with their description
            npc_descriptions =
              Enum.map(npcs_here, fn npc ->
                npc_name = Map.get(npc, :name) || "Unknown NPC"
                npc_desc = Map.get(npc, :description) || "They look at you with interest."
                "#{npc_name} is here.\n#{npc_desc}"
              end)

            updated_lines ++ npc_descriptions
          else
            description_lines
          end

        # Add item descriptions if any are present
        description_lines =
          if length(items_here) > 0 do
            # Empty line for spacing
            updated_lines = description_lines ++ [""]

            # Add each item with their description
            item_descriptions =
              Enum.map(items_here, fn item ->
                item_name = Map.get(item, :name) || "Unknown Item"
                "You see a #{item_name} on ground"
              end)

            updated_lines ++ item_descriptions
          else
            description_lines
          end

        # Add available exits information
        exits = get_available_exits(x, y, room, game_state)

        description_lines =
          if length(exits) > 0 do
            updated_lines = description_lines ++ [""]
            exit_text = "Exits: " <> Enum.join(exits, ", ")
            updated_lines ++ [exit_text]
          else
            description_lines ++ ["", "There are no obvious exits."]
          end

        # To see if there are monsters
        monsters =
          Enum.filter(game_state.monsters, fn value ->
            value[:position] == game_state.player_position
          end)

        monster_count = Enum.count(monsters)

        description_lines =
          description_lines ++
            case monster_count do
              0 ->
                [""]

              1 ->
                monster = Enum.at(monsters, 0)

                monster_desc =
                  if monster[:description] && monster[:description] != "",
                    do: "\n" <> monster[:description],
                    else: ""

                ["", "There is a " <> monster[:name] <> " here." <> monster_desc]

              _ ->
                monster_descriptions =
                  Enum.map_join(monsters, ", ", fn monster ->
                    "a " <> to_string(monster[:name])
                  end)

                [
                  "",
                  "There are " <>
                    to_string(monster_count) <>
                    " monsters! The monsters include " <>
                    monster_descriptions <> "."
                ]
            end

        {description_lines, game_state}

      downcased_command == "stats" ->
        stats = game_state.player_stats

        response = [
          "Character Stats:",
          "  Health: #{stats.health}/#{stats.max_health}",
          "  Stamina: #{stats.stamina}/#{stats.max_stamina}",
          "  Mana: #{stats.mana}/#{stats.max_mana}"
        ]

        {response, game_state}

      downcased_command == "position" ->
        {x, y} = game_state.player_position
        {["You are at position (#{x}, #{y})."], game_state}

      downcased_command == "inventory" ->
        {["Your inventory is empty. (Feature coming soon!)"], game_state}

      downcased_command == "npc" ->
        {x, y} = game_state.player_position
        npcs_here = get_npcs_at_location(x, y, game_state.character.current_zone_id)

        if length(npcs_here) > 0 do
          response =
            ["NPCs in this area:"] ++
              Enum.flat_map(npcs_here, fn npc ->
                npc_name = Map.get(npc, :name) || "Unknown NPC"
                npc_desc = Map.get(npc, :description) || "They look at you with interest."
                ["", "#{npc_name}:", npc_desc]
              end)

          {response, game_state}
        else
          {["There are no NPCs in this area."], game_state}
        end

      downcased_command in ["north", "n"] ->
        execute_movement(game_state, "ArrowUp")

      downcased_command in ["south", "s"] ->
        execute_movement(game_state, "ArrowDown")

      downcased_command in ["east", "e"] ->
        execute_movement(game_state, "ArrowRight")

      downcased_command in ["west", "w"] ->
        execute_movement(game_state, "ArrowLeft")

      downcased_command in ["northeast", "ne"] ->
        execute_movement(game_state, "northeast")

      downcased_command in ["southeast", "se"] ->
        execute_movement(game_state, "southeast")

      downcased_command in ["northwest", "nw"] ->
        execute_movement(game_state, "northwest")

      downcased_command in ["southwest", "sw"] ->
        execute_movement(game_state, "southwest")

      # Admin zone editing commands
      downcased_command == "create room" or String.starts_with?(downcased_command, "create room ") ->
        handle_create_room_command(command, game_state)

      downcased_command == "delete room" or String.starts_with?(downcased_command, "delete room ") ->
        handle_delete_room_command(command, game_state)

      downcased_command == "create door" or String.starts_with?(downcased_command, "create door ") ->
        handle_create_door_command(command, game_state)

      downcased_command == "delete door" or String.starts_with?(downcased_command, "delete door ") ->
        handle_delete_door_command(command, game_state)

      downcased_command == "accept" ->
        execute_accept_quest(game_state)

      downcased_command == "deny" ->
        execute_deny_quest(game_state)

      true ->
        # Check if it's a talk command
        case parse_talk_command(command) do
          {:ok, npc_name} ->
            execute_talk_command(game_state, npc_name)

          :error ->
            # Check if it's a quest command
            case parse_quest_command(command) do
              {:ok, npc_name} ->
                execute_quest_command(game_state, npc_name)

              :error ->
                # Check if it's a deliver_quest command
                case parse_deliver_quest_command(command) do
                  {:ok, npc_name} ->
                    execute_deliver_quest_command(game_state, npc_name)

                  :error ->
                    # Check if it's a pickup command
                    case parse_pickup_command(command) do
                      {:ok, item_name} ->
                        execute_pickup_command(game_state, item_name)

                      :error ->
                        # Check if it's an unlock command
                        case parse_unlock_command(command) do
                          {:ok, direction, item_name} ->
                            execute_unlock_command(game_state, direction, item_name)

                          :error ->
                            # Check if it's a poke command
                            case parse_poke_command(command) do
                              {:ok, character_name} ->
                                execute_poke_command(game_state, character_name)

                              :error ->
                                {[
                                   "Unknown command: '#{command}'. Type 'help' for available commands."
                                 ], game_state}
                            end
                        end
                    end
                end
            end
        end
    end
  end

  # Handle create room command
  defp handle_create_room_command(command, game_state) do
    case parse_create_room_command(command) do
      {:ok, direction} ->
        # Check if character has admin stick
        if AdminStick.has_admin_stick?(game_state.character.id) do
          create_room_in_direction(game_state, direction)
        else
          {["you do not wield powerful enough magic to change the very earth you stand on"],
           game_state}
        end

      :error ->
        {["Invalid create room command. Usage: create room [direction]"], game_state}
    end
  end

  # Handle delete room command
  defp handle_delete_room_command(command, game_state) do
    case parse_delete_room_command(command) do
      {:ok, direction} ->
        # Check if character has admin stick
        if AdminStick.has_admin_stick?(game_state.character.id) do
          delete_room_in_direction(game_state, direction)
        else
          {["you do not wield powerful enough magic to change the very earth you stand on"],
           game_state}
        end

      :error ->
        {["Invalid delete room command. Usage: delete room [direction]"], game_state}
    end
  end

  # Handle create door command
  defp handle_create_door_command(command, game_state) do
    case parse_create_door_command(command) do
      {:ok, direction} ->
        # Check if character has admin stick
        if AdminStick.has_admin_stick?(game_state.character.id) do
          create_door_in_direction(game_state, direction)
        else
          {["you do not wield powerful enough magic to change the very earth you stand on"],
           game_state}
        end

      :error ->
        {["Invalid create door command. Usage: create door [direction]"], game_state}
    end
  end

  # Handle delete door command
  defp handle_delete_door_command(command, game_state) do
    case parse_delete_door_command(command) do
      {:ok, direction} ->
        # Check if character has admin stick
        if AdminStick.has_admin_stick?(game_state.character.id) do
          delete_door_in_direction(game_state, direction)
        else
          {["you do not wield powerful enough magic to change the very earth you stand on"],
           game_state}
        end

      :error ->
        {["Invalid delete door command. Usage: delete door [direction]"], game_state}
    end
  end

  # Create a room in the specified direction
  defp create_room_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    # Get current room
    current_room = GameMap.get_room_by_coordinates(zone_id, x, y, 0)

    case current_room do
      nil ->
        {["You must be in a valid room to create new rooms."], game_state}

      _ ->
        # Calculate new room coordinates based on direction
        {new_x, new_y} = calculate_coordinates_from_direction({x, y}, direction)

        # Check if room already exists at those coordinates
        existing_room = GameMap.get_room_by_coordinates(zone_id, new_x, new_y, 0)

        case existing_room do
          nil ->
            # Room doesn't exist, create the new room with default description
            case GameMap.create_room(%{
                   name: "New Room",
                   description: "A newly created room",
                   x_coordinate: new_x,
                   y_coordinate: new_y,
                   z_coordinate: 0,
                   zone_id: zone_id
                 }) do
              {:ok, new_room} ->
                # Create door from current room to new room
                case GameMap.create_door(%{
                       from_room_id: current_room.id,
                       to_room_id: new_room.id,
                       direction: direction
                     }) do
                  {:ok, _door} ->
                    {[
                       "Successfully created a new room to the #{direction}.",
                       "A door has been created connecting the rooms."
                     ], game_state}

                  {:error, _changeset} ->
                    # Clean up the room if door creation fails
                    GameMap.delete_room(new_room)
                    {["Failed to create door to new room."], game_state}
                end

              {:error, _changeset} ->
                {["Failed to create new room."], game_state}
            end

          _ ->
            {["A room already exists in that direction."], game_state}
        end
    end
  end

  # Delete a room in the specified direction
  defp delete_room_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    # Get current room
    current_room = GameMap.get_room_by_coordinates(zone_id, x, y, 0)

    case current_room do
      nil ->
        {["You must be in a valid room to delete rooms."], game_state}

      _ ->
        # Calculate coordinates based on direction
        {target_x, target_y} = calculate_coordinates_from_direction({x, y}, direction)

        # Find room in that direction
        target_room = GameMap.get_room_by_coordinates(zone_id, target_x, target_y, 0)

        case target_room do
          nil ->
            {["There is no room in that direction to delete."], game_state}

          room ->
            # Check if this is the starting room or a critical room
            # For now, we'll allow deletion but could add restrictions
            case GameMap.delete_room(room) do
              {:ok, _} ->
                {["Successfully deleted the room to the #{direction}."], game_state}

              {:error, _} ->
                {["Failed to delete the room."], game_state}
            end
        end
    end
  end

  # Create a door in the specified direction
  defp create_door_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    # Get current room
    current_room = GameMap.get_room_by_coordinates(zone_id, x, y, 0)

    case current_room do
      nil ->
        {["You must be in a valid room to create doors."], game_state}

      _ ->
        # Calculate coordinates based on direction
        {target_x, target_y} = calculate_coordinates_from_direction({x, y}, direction)

        # Find room in that direction
        target_room = GameMap.get_room_by_coordinates(zone_id, target_x, target_y, 0)

        case target_room do
          nil ->
            {["There is no room in that direction to create a door to."], game_state}

          room ->
            # Check if door already exists
            existing_door = GameMap.get_door_in_direction(current_room.id, direction)

            case existing_door do
              nil ->
                # Door doesn't exist, create it
                case GameMap.create_door(%{
                       from_room_id: current_room.id,
                       to_room_id: room.id,
                       direction: direction
                     }) do
                  {:ok, _door} ->
                    {["Successfully created a door to the #{direction}."], game_state}

                  {:error, _changeset} ->
                    {["Failed to create door."], game_state}
                end

              _ ->
                {["A door already exists in that direction."], game_state}
            end
        end
    end
  end

  # Delete a door in the specified direction
  defp delete_door_in_direction(game_state, direction) do
    {x, y} = game_state.player_position
    zone_id = game_state.character.current_zone_id

    # Get current room
    current_room = GameMap.get_room_by_coordinates(zone_id, x, y, 0)

    case current_room do
      nil ->
        {["You must be in a valid room to delete doors."], game_state}

      _ ->
        # Check if door exists in that direction
        door = GameMap.get_door_in_direction(current_room.id, direction)

        case door do
          nil ->
            {["There is no door in that direction to delete."], game_state}

          _ ->
            # Door exists, delete it
            case GameMap.delete_door(door) do
              {:ok, _} ->
                {["Successfully deleted the door to the #{direction}."], game_state}

              {:error, _} ->
                {["Failed to delete the door."], game_state}
            end
        end
    end
  end

  # Calculate coordinates based on direction
  defp calculate_coordinates_from_direction({x, y}, direction) do
    case String.downcase(direction) do
      "north" -> {x, y - 1}
      "south" -> {x, y + 1}
      "east" -> {x + 1, y}
      "west" -> {x - 1, y}
      "northeast" -> {x + 1, y - 1}
      "northwest" -> {x - 1, y - 1}
      "southeast" -> {x + 1, y + 1}
      "southwest" -> {x - 1, y + 1}
      # Default to current position for invalid directions
      _ -> {x, y}
    end
  end

  # Get items at a specific location
  defp get_items_at_location(x, y, _zone_id) do
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

    # Also check for items directly in Item table with matching location
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

    # Combine both results and remove duplicates based on name
    all_items = room_items ++ direct_items
    all_items |> Enum.uniq_by(& &1.name)
  end

  # Parse talk command to extract NPC name
  def parse_talk_command(command) do
    # Match patterns like: talk "npc name", talk 'npc name', talk npc_name
    cond do
      # Match talk "npc name" or talk 'npc name'
      Regex.match?(~r/^talk\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^talk\s+["'](.+)["']\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      # Match talk npc_name (single word, no quotes)
      Regex.match?(~r/^talk\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^talk\s+(\w+)\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse quest command to extract NPC name
  def parse_quest_command(command) do
    # Match patterns like: quest "npc name", quest 'npc name', quest npc_name
    cond do
      # Match quest "npc name" or quest 'npc name'
      Regex.match?(~r/^quest\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^quest\s+["'](.+)["']\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      # Match quest npc_name (single word, no quotes)
      Regex.match?(~r/^quest\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^quest\s+(\w+)\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse deliver_quest command to extract NPC name
  def parse_deliver_quest_command(command) do
    # Match patterns like: deliver_quest "npc name", deliver_quest 'npc name', deliver_quest npc_name
    cond do
      # Match deliver_quest "npc name" or deliver_quest 'npc name'
      Regex.match?(~r/^deliver_quest\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^deliver_quest\s+["'](.+)["']\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      # Match deliver_quest npc_name (single word, no quotes)
      Regex.match?(~r/^deliver_quest\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^deliver_quest\s+(\w+)\s*$/i, command) do
          [_, npc_name] -> {:ok, String.trim(npc_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Parse pickup command to extract item name
  def parse_pickup_command(command) do
    # Match patterns like: pickup "item name", pickup 'item name', pickup item_name
    cond do
      # Match pickup "item name" or pickup 'item name'
      Regex.match?(~r/^pickup\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^pickup\s+["'](.+)["']\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      # Match pickup item_name (single word, no quotes)
      Regex.match?(~r/^pickup\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^pickup\s+(\w+)\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Execute pickup command with a specific item name
  def execute_pickup_command(game_state, item_name) do
    {x, y} = game_state.player_position
    items_here = get_items_at_location(x, y, game_state.character.current_zone_id)

    # Find the item by name (case-insensitive)
    target_item =
      Enum.find(items_here, fn item ->
        String.downcase(item.name || "") == String.downcase(item_name)
      end)

    case target_item do
      nil ->
        if length(items_here) > 0 do
          # credo:disable-for-next-line Credo.Check.Refactor.EnumMapJoin
          available_names = Enum.map_join(items_here, ", ", & &1.name)

          response = [
            "There is no item named '#{item_name}' here.",
            "Available items: #{available_names}"
          ]

          {response, game_state}
        else
          {["There are no items here to pick up."], game_state}
        end

      item ->
        # Check if item can be picked up (assuming all items can be picked up for now)
        # In the future, you might want to add a "pickupable" field to items

        # Add item to player's inventory
        updated_inventory = [
          %{
            id: item[:id],
            name: item.name,
            type: item.item_type || "misc",
            quantity: item.quantity || 1,
            damage: item[:damage],
            defense: item[:defense],
            effect: item[:effect],
            description: item[:description]
          }
          | game_state.inventory_items
        ]

        # Remove item from the room (this would need database implementation)
        # For now, we'll just update the game state

        response = [
          "You pick up #{item.name}.",
          "#{item.name} has been added to your inventory."
        ]

        updated_game_state = %{game_state | inventory_items: updated_inventory}

        # NOTE: Remove item from database room/location
        # This would require calling something like:
        # Shard.Items.remove_item_from_location(item.id, "#{x},#{y},0")

        {response, updated_game_state}
    end
  end
end
