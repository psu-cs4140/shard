defmodule ShardWeb.UserLive.PokeCommands do
  @moduledoc """
  Commands related to poking other players.
  """

  # Execute poke command with a specific character name
  def execute_poke_command(game_state, character_name) do
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
          send_poke_notification(target_character, game_state.character)

          {["You poke #{target_character.name}."], game_state}
        end
    end
  end

  # Send poke notification to target character
  defp send_poke_notification(target_character, sender_character) do
    # Broadcast poke notification to the target character
    Phoenix.PubSub.broadcast(
      Shard.PubSub,
      "character:#{target_character.id}",
      {:poke_notification, sender_character.name}
    )
  end
end
