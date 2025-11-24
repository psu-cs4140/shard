defmodule ShardWeb.UserLive.Commands3 do
  @moduledoc """
  Multiplayer commands for the MUD game terminal.
  """

  alias Shard.Characters
  alias Phoenix.PubSub

  @doc """
  Parse and execute the poke command.
  Returns {response, game_state} tuple.
  """
  def execute_poke_command(game_state, target_character_name) do
    current_character = game_state.character
    current_character_name = current_character.name

    # Don't allow poking yourself
    if String.downcase(target_character_name) == String.downcase(current_character_name) do
      {["You cannot poke yourself!"], game_state}
    else
      case find_target_character(target_character_name) do
        nil ->
          {["No character named '#{target_character_name}' is currently online."], game_state}

        target_character ->
          send_poke_notification(current_character_name, target_character)
          {["You poke #{target_character.name}."], game_state}
      end
    end
  end

  @doc """
  Parse poke command to extract target character name.
  Supports formats like: poke "character name", poke 'character name', poke character_name
  """
  def parse_poke_command(command) do
    # Trim the entire command first to handle leading/trailing whitespace
    trimmed_command = String.trim(command)

    cond do
      # Match poke "character name" or poke 'character name'
      Regex.match?(~r/^poke\s+["'](.+)["']\s*$/i, trimmed_command) ->
        case Regex.run(~r/^poke\s+["'](.+)["']\s*$/i, trimmed_command) do
          [_, character_name] -> {:ok, String.trim(character_name)}
          _ -> :error
        end

      # Match poke character_name (single word, no quotes)
      Regex.match?(~r/^poke\s+(\w+)\s*$/i, trimmed_command) ->
        case Regex.run(~r/^poke\s+(\w+)\s*$/i, trimmed_command) do
          [_, character_name] -> {:ok, String.trim(character_name)}
          _ -> :error
        end

      true ->
        :error
    end
  end

  @doc """
  Handle incoming poke notifications from other players.
  """
  def handle_poke_notification(terminal_state, poker_name) do
    poke_message = "#{poker_name} pokes you!"

    new_output = terminal_state.output ++ [poke_message] ++ [""]
    Map.put(terminal_state, :output, new_output)
  end

  # Private helper functions

  defp find_target_character(character_name) do
    # Find character by name (case-insensitive)
    try do
      characters = Characters.list_characters()

      Enum.find(characters, fn character ->
        String.downcase(character.name) == String.downcase(character_name)
      end)
    rescue
      _ -> nil
    end
  end

  defp send_poke_notification(poker_name, target_character) do
    # Create a unique channel for the target character
    target_channel = "character:#{target_character.id}"

    # Broadcast the poke notification to the target character's channel
    PubSub.broadcast(
      Shard.PubSub,
      target_channel,
      {:poke_notification, poker_name}
    )
  end

  @doc """
  Subscribe a character to their personal notification channel.
  This should be called when a character enters the game.
  """
  def subscribe_to_character_notifications(character_id) do
    channel = "character:#{character_id}"
    PubSub.subscribe(Shard.PubSub, channel)
  end

  @doc """
  Unsubscribe a character from their personal notification channel.
  This should be called when a character leaves the game.
  """
  def unsubscribe_from_character_notifications(character_id) do
    channel = "character:#{character_id}"
    PubSub.unsubscribe(Shard.PubSub, channel)
  end

  @doc """
  Unsubscribe a character from their player name-based notification channel.
  """
  def unsubscribe_from_player_notifications(character_name) do
    channel = "player:#{character_name}"
    PubSub.unsubscribe(Shard.PubSub, channel)
  end
end
