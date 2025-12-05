defmodule ShardWeb.UserLive.CommandsWithSpells do
  @moduledoc """
  Extends Commands1 with spell casting functionality.
  Import this module instead of Commands1 to get spell support.
  """

  import ShardWeb.UserLive.SpellCommands

  # Delegate to Commands1 for most commands, but intercept for spells
  def process_command(command, game_state) do
    case String.downcase(command) do
      "spells" ->
        execute_spells_command(game_state)

      "help" ->
        response = [
          "Available commands:",
          "  look - Examine your surroundings",
          "  attack - Attack an enemy in the room (if in combat)",
          "  flee - Attempt to flee from combat",
          "  stats - Show your character stats",
          "  position - Show your current position",
          "  inventory - Show your inventory (coming soon)",
          "  pickup \"item_name\" - Pick up an item from the room",
          "  use \"item_name\" - Use an item from your inventory",
          "  npc - Show descriptions of NPCs in this room",
          "  talk \"npc_name\" - Talk to a specific NPC",
          "  quest \"npc_name\" - Get quest from a specific NPC",
          "  accept - Accept a quest offer",
          "  deny - Deny a quest offer",
          "  deliver_quest \"npc_name\" - Deliver completed quest to NPC",
          "  poke \"character_name\" - Poke another player",
          "  cast \"spell_name\" - Cast a spell you know",
          "  spells - List all spells you know",
          "  north/south/east/west - Move in cardinal directions",
          "  northeast/southeast/northwest/southwest - Move diagonally",
          "  Shortcuts: n/s/e/w/ne/se/nw/sw",
          "  unlock [direction] with [item_name] - Unlock a door using an item",
          "  help - Show this help message"
        ]

        {response, game_state}

      _ ->
        # Check if it's a cast command
        case parse_cast_command(command) do
          {:ok, spell_name} ->
            execute_cast_command(game_state, spell_name)

          :error ->
            # Fall through to Commands1 for other commands
            ShardWeb.UserLive.Commands1.process_command(command, game_state)
        end
    end
  end
end
