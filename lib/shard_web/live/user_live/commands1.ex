# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule ShardWeb.UserLive.Commands1 do
  @moduledoc false
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.QuestHandlers
  import ShardWeb.UserLive.Movement

  # import ShardWeb.UserLive.Commands2,
  #   except: [execute_talk_command: 2, execute_deliver_quest_command: 2, execute_quest_command: 2]

  import ShardWeb.UserLive.Commands3

  import ShardWeb.UserLive.NpcCommands
  import ShardWeb.UserLive.CommandParsers

  #  import ShardWeb.UserLive.ItemCommands

  alias Shard.Map, as: GameMap
  # alias Shard.Items.Item
  # alias Shard.Repo
  # import Ecto.Query

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
          "  equipped - Show your currently equipped items",
          "  equip \"item_name\" - Equip an item from your inventory",
          "  unequip \"item_name\" - Unequip an equipped item",
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
        # Build room description from database
        room_description =
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

        # Check for NPCs at current location
        npcs_here = get_npcs_at_location(x, y, game_state.character.current_zone_id)

        # Check for other players at current location
        other_players = get_other_players_at_location(x, y, game_state.character.current_zone_id, game_state.character.id)

        # Check for items at current location
        items_here =
          ShardWeb.UserLive.ItemCommands.get_items_at_location(
            x,
            y,
            game_state.character.current_zone_id
          )

        description_lines = [room_description]

        # Add NPC descriptions if any are present
        description_lines =
          if Enum.empty?(npcs_here) do
            description_lines
          else
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
          end

        # Add other player descriptions if any are present
        description_lines =
          if Enum.empty?(other_players) do
            description_lines
          else
            # Empty line for spacing
            updated_lines = description_lines ++ [""]

            # Add each player
            player_descriptions =
              Enum.map(other_players, fn player ->
                player_name = Map.get(player, :name) || "Unknown Player"
                "#{player_name} is here."
              end)

            updated_lines ++ player_descriptions
          end

        # Add item descriptions if any are present
        description_lines =
          if Enum.empty?(items_here) do
            description_lines
          else
            # Empty line for spacing
            updated_lines = description_lines ++ [""]

            # Add each item with their description
            item_descriptions =
              Enum.map(items_here, fn item ->
                item_name = Map.get(item, :name) || "Unknown Item"
                "You see a #{item_name} on ground"
              end)

            updated_lines ++ item_descriptions
          end

        # Add available exits information
        exits = get_available_exits(x, y, room, game_state)

        description_lines =
          if Enum.empty?(exits) do
            description_lines ++ ["", "There are no obvious exits."]
          else
            updated_lines = description_lines ++ [""]
            exit_text = "Exits: " <> Enum.join(exits, ", ")
            updated_lines ++ [exit_text]
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
        inventory_items = game_state.inventory_items

        if Enum.empty?(inventory_items) do
          {["Your inventory is empty."], game_state}
        else
          response =
            ["Your inventory contains:"] ++
              Enum.map(inventory_items, fn inv_item ->
                item_name = inv_item.item.name
                quantity = inv_item.quantity
                equipped_text = if inv_item.equipped, do: " (equipped)", else: ""

                if quantity > 1 do
                  "  #{item_name} x#{quantity}#{equipped_text}"
                else
                  "  #{item_name}#{equipped_text}"
                end
              end)

          {response, game_state}
        end

      downcased_command == "npc" ->
        {x, y} = game_state.player_position
        npcs_here = get_npcs_at_location(x, y, game_state.character.current_zone_id)

        if Enum.empty?(npcs_here) do
          {["There are no NPCs in this area."], game_state}
        else
          response =
            ["NPCs in this area:"] ++
              Enum.flat_map(npcs_here, fn npc ->
                npc_name = Map.get(npc, :name) || "Unknown NPC"
                npc_desc = Map.get(npc, :description) || "They look at you with interest."
                ["", "#{npc_name}:", npc_desc]
              end)

          {response, game_state}
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
        ShardWeb.UserLive.AdminCommands.handle_create_room_command(command, game_state)

      downcased_command == "delete room" or String.starts_with?(downcased_command, "delete room ") ->
        ShardWeb.UserLive.AdminCommands.handle_delete_room_command(command, game_state)

      downcased_command == "create door" or String.starts_with?(downcased_command, "create door ") ->
        ShardWeb.UserLive.AdminCommands.handle_create_door_command(command, game_state)

      downcased_command == "delete door" or String.starts_with?(downcased_command, "delete door ") ->
        ShardWeb.UserLive.AdminCommands.handle_delete_door_command(command, game_state)

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
                    case ShardWeb.UserLive.ItemCommands.parse_pickup_command(command) do
                      {:ok, item_name} ->
                        ShardWeb.UserLive.ItemCommands.execute_pickup_command(
                          game_state,
                          item_name
                        )

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
                                # Check if it's an equipped command
                                case parse_equipped_command(command) do
                                  :ok ->
                                    execute_equipped_command(game_state)

                                  :error ->
                                    # Check if it's an equip command
                                    case parse_equip_command(command) do
                                      {:ok, item_name} ->
                                        execute_equip_command(game_state, item_name)

                                      :error ->
                                        # Check if it's an unequip command
                                        case parse_unequip_command(command) do
                                          {:ok, item_name} ->
                                            execute_unequip_command(game_state, item_name)

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
        end
    end
  end

  # Helper function to get other players at the same location
  defp get_other_players_at_location(x, y, zone_id, current_character_id) do
    try do
      # Get all characters at the same coordinates, excluding the current character
      Shard.Characters.list_characters()
      |> Enum.filter(fn character ->
        character.id != current_character_id &&
        character.current_zone_id == zone_id &&
        character.x_coordinate == x &&
        character.y_coordinate == y
      end)
    rescue
      _ -> []
    end
  end
end
