defmodule ShardWeb.UserLive.MudGameLive2 do
  @moduledoc """
  Helper functions for MudGameLive split into a separate module.
  """

  import Phoenix.Component
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.Commands3
  alias Phoenix.PubSub

  def get_character_from_params(params) do
    case Map.get(params, "character_id") do
      nil ->
        {:error, :no_character}

      character_id ->
        try do
          character = Shard.Characters.get_character!(character_id)
          {:ok, character}
        rescue
          _ -> {:error, :no_character}
        end
    end
  end

  def get_character_name(params, character) do
    case Map.get(params, "character_name") do
      nil -> if character, do: character.name, else: "Unknown"
      name -> URI.decode(name)
    end
  end

  def load_character_with_associations(character) do
    try do
      loaded_character =
        Shard.Repo.get!(Shard.Characters.Character, character.id)
        |> Shard.Repo.preload([:character_inventories, :hotbar_slots])

      {:ok, loaded_character}
    rescue
      _ -> {:ok, character}
    end
  end

  def setup_tutorial_content("tutorial_terrain") do
    setup_tutorial_key()
    setup_tutorial_npc()
    setup_tutorial_door()
    :ok
  end

  def setup_tutorial_content(_map_id), do: :ok

  defp setup_tutorial_key do
    case Shard.Items.create_tutorial_key() do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
      _other -> :error
    end
  end

  defp setup_tutorial_npc do
    case Shard.Npcs.create_tutorial_npc_goldie() do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
      _other -> :error
    end
  end

  defp setup_tutorial_door do
    case Shard.Items.create_dungeon_door() do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
    end
  end

  def initialize_game_state(socket, character, map_id, character_name) do
    # Use the helper function from MudGameHelpers
    {:ok, assigns} =
      ShardWeb.UserLive.MudGameHelpers.initialize_game_state(character, map_id, character_name)

    # Extract the states
    game_state = assigns.game_state
    terminal_state = assigns.terminal_state
    chat_state = assigns.chat_state
    modal_state = assigns.modal_state

    PubSub.subscribe(
      Shard.PubSub,
      ShardWeb.UserLive.MudGameHelpers.posn_to_room_channel(game_state.player_position)
    )

    # Subscribe to character-specific notifications for poke commands
    subscribe_to_character_notifications(character.id)

    # Also subscribe to player name-based channel as backup
    PubSub.subscribe(Shard.PubSub, "player:#{character.name}")

    socket =
      socket
      |> assign(:game_state, game_state)
      |> assign(:terminal_state, terminal_state)
      |> assign(:chat_state, chat_state)
      |> assign(:modal_state, modal_state)
      |> assign(:available_exits, compute_available_exits(game_state.player_position))
      |> assign(:character_name, character_name)
      |> assign(:active_tab, assigns.active_tab)

    {:ok, socket}
  end

  def add_message(socket, message) do
    new_output = socket.assigns.terminal_state.output ++ [message] ++ [""]
    ts1 = Map.put(socket.assigns.terminal_state, :output, new_output)
    assign(socket, :terminal_state, ts1)
  end
end
