defmodule ShardWeb.UserLive.AdminCommands do
  @moduledoc """
  Module for handling admin-specific commands like creating/deleting rooms and doors.
  """

  alias Shard.Items.AdminStick
  alias ShardWeb.UserLive.AdminZoneEditor

  # Handle create room command
  def handle_create_room_command(command, game_state) do
    case parse_create_room_command(command) do
      {:ok, direction} ->
        # Check if character has admin stick
        if AdminStick.has_admin_stick?(game_state.character.id) do
          AdminZoneEditor.create_room_in_direction(game_state, direction)
        else
          {["you do not wield powerful enough magic to change the very earth you stand on"],
           game_state}
        end

      :error ->
        {["Invalid create room command. Usage: create room [direction]"], game_state}
    end
  end

  # Handle delete room command
  def handle_delete_room_command(command, game_state) do
    case parse_delete_room_command(command) do
      {:ok, direction} ->
        # Check if character has admin stick
        if AdminStick.has_admin_stick?(game_state.character.id) do
          AdminZoneEditor.delete_room_in_direction(game_state, direction)
        else
          {["you do not wield powerful enough magic to change the very earth you stand on"],
           game_state}
        end

      :error ->
        {["Invalid delete room command. Usage: delete room [direction]"], game_state}
    end
  end

  # Handle create door command
  def handle_create_door_command(command, game_state) do
    case parse_create_door_command(command) do
      {:ok, direction} ->
        # Check if character has admin stick
        if AdminStick.has_admin_stick?(game_state.character.id) do
          AdminZoneEditor.create_door_in_direction(game_state, direction)
        else
          {["you do not wield powerful enough magic to change the very earth you stand on"],
           game_state}
        end

      :error ->
        {["Invalid create door command. Usage: create door [direction]"], game_state}
    end
  end

  # Handle delete door command
  def handle_delete_door_command(command, game_state) do
    case parse_delete_door_command(command) do
      {:ok, direction} ->
        # Check if character has admin stick
        if AdminStick.has_admin_stick?(game_state.character.id) do
          AdminZoneEditor.delete_door_in_direction(game_state, direction)
        else
          {["you do not wield powerful enough magic to change the very earth you stand on"],
           game_state}
        end

      :error ->
        {["Invalid delete door command. Usage: delete door [direction]"], game_state}
    end
  end

  # Parse create room command: "create room <direction>"
  def parse_create_room_command(command) do
    # Match patterns like: create room north, create room "north"
    if Regex.match?(~r/^create\s+room\s+["']?(\w+)["']?\s*$/i, command) do
      case Regex.run(~r/^create\s+room\s+["']?(\w+)["']?\s*$/i, command) do
        [_, direction] -> {:ok, String.trim(direction) |> String.downcase()}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse delete room command: "delete room <direction>"
  def parse_delete_room_command(command) do
    # Match patterns like: delete room north, delete room "north"
    if Regex.match?(~r/^delete\s+room\s+["']?(\w+)["']?\s*$/i, command) do
      case Regex.run(~r/^delete\s+room\s+["']?(\w+)["']?\s*$/i, command) do
        [_, direction] -> {:ok, String.trim(direction) |> String.downcase()}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse create door command: "create door <direction>"
  def parse_create_door_command(command) do
    # Match patterns like: create door north, create door "north"
    if Regex.match?(~r/^create\s+door\s+["']?(\w+)["']?\s*$/i, command) do
      case Regex.run(~r/^create\s+door\s+["']?(\w+)["']?\s*$/i, command) do
        [_, direction] -> {:ok, String.trim(direction) |> String.downcase()}
        _ -> :error
      end
    else
      :error
    end
  end

  # Parse delete door command: "delete door <direction>"
  def parse_delete_door_command(command) do
    # Match patterns like: delete door north, delete door "north"
    if Regex.match?(~r/^delete\s+door\s+["']?(\w+)["']?\s*$/i, command) do
      case Regex.run(~r/^delete\s+door\s+["']?(\w+)["']?\s*$/i, command) do
        [_, direction] -> {:ok, String.trim(direction) |> String.downcase()}
        _ -> :error
      end
    else
      :error
    end
  end
end
