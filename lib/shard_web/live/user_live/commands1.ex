# credo:disable-for-this-file Credo.Check.Refactor.Nesting
# credo:disable-for-this-file Credo.Check.Refactor.CyclomaticComplexity
defmodule ShardWeb.UserLive.Commands1 do
  @moduledoc false
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.QuestHandlers, except: [execute_quest_command: 2]
  import ShardWeb.UserLive.Movement

  # import ShardWeb.UserLive.Commands2,
  #   except: [execute_talk_command: 2, execute_deliver_quest_command: 2, execute_quest_command: 2]

  import ShardWeb.UserLive.Commands3

  import ShardWeb.UserLive.NpcCommands
  import ShardWeb.UserLive.CommandParsers

  #  import ShardWeb.UserLive.ItemCommands

  alias Shard.Map, as: GameMap
  alias Shard.Repo
  alias Shard.Mining
  import Ecto.Query
  # alias Shard.Items.Item

  # Process terminal commands
  def process_command(command, game_state) do
    downcased_command = String.downcase(command)

    cond do
      downcased_command == "mine start" ->
        start_mining(game_state)

      downcased_command == "mine stop" ->
        stop_mining(game_state)

      downcased_command == "chop start" ->
        start_chopping(game_state)

      downcased_command == "chop stop" ->
        stop_chopping(game_state)

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
          "  accept_quest \"npc_name\" \"quest_title\" - Accept a specific quest from an NPC",
          "  deliver_quest \"npc_name\" - Deliver completed quest to NPC",
          "  poke \"character_name\" - Poke another player",
          "  equipped - Show your currently equipped items",
          "  equip \"item_name\" - Equip an item from your inventory",
          "  unequip \"item_name\" - Unequip an equipped item",
          "  use \"item_name\" - Use an item from your inventory",
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
        other_players =
          get_other_players_at_location(
            x,
            y,
            game_state.character.current_zone_id,
            game_state.character.id
          )

        # Check for items at current location
        items_here =
          ShardWeb.UserLive.ItemCommands.get_items_at_location(
            x,
            y,
            game_state.character.current_zone_id
          )

        description_lines = [room_description]

        # Add NPC descriptions if any are present
        description_lines = description_lines ++ get_npc_descriptions(npcs_here)

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
            # Only create NPCs when player explicitly tries to talk
            ShardWeb.AdminLive.NpcHelpers.ensure_tutorial_npcs_exist()
            execute_talk_command(game_state, npc_name)

          :error ->
            # Check if it's a quest command
            case parse_quest_command(command) do
              {:ok, npc_name} ->
                # Only create NPCs when player explicitly tries to get quests
                ShardWeb.AdminLive.NpcHelpers.ensure_tutorial_npcs_exist()
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
                            case ShardWeb.UserLive.CommandParsers.parse_poke_command(command) do
                              {:ok, character_name} ->
                                execute_poke_command_local(game_state, character_name)

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
                                            # Check if it's an accept_quest command
                                            case parse_accept_quest_command(command) do
                                              {:ok, npc_name, quest_title} ->
                                                # Only create NPCs when player explicitly tries to accept quests
                                                ShardWeb.AdminLive.NpcHelpers.ensure_tutorial_npcs_exist()

                                                execute_accept_quest_command(
                                                  game_state,
                                                  npc_name,
                                                  quest_title
                                                )

                                              :error ->
                                                # Check if it's a use command
                                                case parse_use_command(command) do
                                                  {:ok, item_name} ->
                                                    execute_use_command(game_state, item_name)

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
    end
  end

  defp start_mining(game_state) do
    zone = GameMap.get_zone!(game_state.character.current_zone_id)

    if zone.slug != "mines" do
      {["You need to be in the Mines to start mining."], game_state}
    else
      with {:ok, %{character: char, mining_inventory: _inv, ticks_applied: ticks}} <-
             Mining.apply_mining_ticks(game_state.character),
           {:ok, mining_char} <- Mining.start_mining(char) do
        send(self(), {:mining_started, ticks})

        updated_game_state =
          %{game_state | character: mining_char, mining_active: true}
          |> refresh_inventory()

        message = "You swing your pickaxe and begin mining."

        {[message], updated_game_state}
      else
        _ -> {["Failed to start mining."], game_state}
      end
    end
  end

  defp stop_mining(game_state) do
    if game_state.mining_active do
      case Mining.stop_mining(game_state.character) do
        {:ok, %{character: char, mining_inventory: _inv, ticks_applied: _ticks}} ->
          send(self(), :mining_stopped)

          updated_game_state =
            %{game_state | character: char, mining_active: false}
            |> refresh_inventory()

          message = "You stop to rest, laying your pickaxe down and wiping your brow."

          {[message], updated_game_state}

        _ ->
          {["Failed to stop mining."], game_state}
      end
    else
      {["You are not mining."], game_state}
    end
  end

  defp refresh_inventory(game_state) do
    %{
      game_state
      | inventory_items:
          ShardWeb.UserLive.CharacterHelpers.load_character_inventory(game_state.character)
    }
  end

  defp start_chopping(game_state) do
    zone = GameMap.get_zone!(game_state.character.current_zone_id)

    if zone.slug != "whispering_forest" do
      {["You need to be in the Whispering Forest to start chopping."], game_state}
    else
      with {:ok, %{character: char, chopping_inventory: _inv, ticks_applied: ticks}} <-
             Shard.Forest.apply_chopping_ticks(game_state.character),
           {:ok, chopping_char} <- Shard.Forest.start_chopping(char) do
        send(self(), {:chopping_started, ticks})

        updated_game_state =
          %{game_state | character: chopping_char, chopping_active: true}
          |> refresh_inventory()

        message = "You raise your axe and begin chopping."

        {[message], updated_game_state}
      else
        _ -> {["Failed to start chopping."], game_state}
      end
    end
  end

  defp stop_chopping(game_state) do
    if game_state.chopping_active do
      case Shard.Forest.stop_chopping(game_state.character) do
        {:ok, %{character: char, chopping_inventory: _inv, ticks_applied: _ticks}} ->
          send(self(), :chopping_stopped)

          updated_game_state =
            %{game_state | character: char, chopping_active: false}
            |> refresh_inventory()

          message =
            "You lower your axe, brush off the wood chips from your clothes, and catch your breath."

          {[message], updated_game_state}

        _ ->
          {["Failed to stop chopping."], game_state}
      end
    else
      {["You are not chopping."], game_state}
    end
  end

  # Helper function to get NPC descriptions for a location
  def get_npc_descriptions(npcs_here) do
    if Enum.empty?(npcs_here) do
      []
    else
      # Empty line for spacing
      # Add each NPC with their description
      [""] ++
        Enum.map(npcs_here, fn npc ->
          npc_name = Map.get(npc, :name) || "Unknown NPC"
          npc_desc = Map.get(npc, :description) || "They look at you with interest."
          "#{npc_name} is here.\n#{npc_desc}"
        end)
    end
  end

  # Helper function to get other players at the same location
  defp get_other_players_at_location(x, y, zone_id, current_character_id) do
    try do
      # Get the room at the current coordinates
      room = GameMap.get_room_by_coordinates(zone_id, x, y, 0)

      case room do
        nil ->
          []

        room ->
          # Get all player positions in this room, excluding the current character
          query =
            from(pp in GameMap.PlayerPosition,
              join: c in Shard.Characters.Character,
              on: pp.character_id == c.id,
              where: pp.room_id == ^room.id and pp.character_id != ^current_character_id,
              select: c
            )

          Repo.all(query)
      end
    rescue
      _ -> []
    end
  end

  # Parse use command to extract item name
  defp parse_use_command(command) do
    # Match patterns like: use "item name", use 'item name', use item_name
    cond do
      # Match use "item name" or use 'item name'
      Regex.match?(~r/^use\s+["'](.+)["']\s*$/i, command) ->
        case Regex.run(~r/^use\s+["'](.+)["']\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      # Match use item_name (single word, no quotes)
      Regex.match?(~r/^use\s+(\w+)\s*$/i, command) ->
        case Regex.run(~r/^use\s+(\w+)\s*$/i, command) do
          [_, item_name] -> {:ok, String.trim(item_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  # Execute use command with a specific item name
  defp execute_use_command(game_state, item_name) do
    # Find the item in inventory by name (case-insensitive)
    target_item =
      Enum.find(game_state.inventory_items, fn inv_item ->
        item_display_name = get_item_display_name(inv_item)
        String.downcase(item_display_name) == String.downcase(item_name)
      end)

    case target_item do
      nil ->
        if Enum.empty?(game_state.inventory_items) do
          {["Your inventory is empty."], game_state}
        else
          available_items =
            Enum.map_join(game_state.inventory_items, ", ", &get_item_display_name/1)

          response = [
            "You don't have an item named '#{item_name}' in your inventory.",
            "Available items: #{available_items}"
          ]

          {response, game_state}
        end

      item ->
        # Use the item helper function
        ShardWeb.UserLive.ItemHelpers.use_item(game_state, item)
    end
  end

  # Execute poke command with a specific character name
  defp execute_poke_command_local(game_state, character_name) do
    # Find the target character by name (case-insensitive)
    case Shard.Characters.get_character_by_name(character_name) do
      nil ->
        {["There is no character named '#{character_name}' online."], game_state}

      target_character ->
        # Don't allow poking yourself
        if target_character.id == game_state.character.id do
          {["You cannot poke yourself!"], game_state}
        else
          # Send notification to target character
          send_poke_notification_local(target_character, game_state.character)

          {["You poke #{target_character.name}."], game_state}
        end
    end
  end

  # Send poke notification to target character
  defp send_poke_notification_local(target_character, sender_character) do
    # Broadcast poke notification to the target character
    Phoenix.PubSub.broadcast(
      Shard.PubSub,
      "character:#{target_character.id}",
      {:poke_notification, sender_character.name}
    )
  end

  # Helper function to get item display name from inventory item
  defp get_item_display_name(inv_item) do
    cond do
      inv_item.item && inv_item.item.name -> inv_item.item.name
      inv_item.name -> inv_item.name
      true -> "Unknown Item"
    end
  end
end
