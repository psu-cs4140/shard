defmodule ShardWeb.UserLive.MudGameLive2 do
  @moduledoc """
  Helper functions for MudGameLive split into a separate module.
  """

  import Phoenix.Component
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.CharacterHelpers
  #  import ShardWeb.UserLive.ItemHelpers
  import ShardWeb.UserLive.MonsterComponents
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
    map_data = generate_map_from_database(map_id)
    starting_position = find_valid_starting_position(map_data)

    game_state = build_game_state(character, map_data, map_id, starting_position)
    terminal_state = build_terminal_state(starting_position, map_id)
    modal_state = build_modal_state()

    PubSub.subscribe(Shard.PubSub, posn_to_room_channel(game_state.player_position))

    # Subscribe to character-specific notifications for poke commands
    subscribe_to_character_notifications(character.id)

    # Also subscribe to player name-based channel as backup
    PubSub.subscribe(Shard.PubSub, "player:#{character.name}")

    socket =
      socket
      |> assign(:game_state, game_state)
      |> assign(:terminal_state, terminal_state)
      |> assign(:modal_state, modal_state)
      |> assign(:available_exits, compute_available_exits(game_state.player_position))
      |> assign(:character_name, character_name)
      |> assign(:active_tab, "terminal")
      |> assign(:chat_state, %{messages: [], current_message: ""})

    {:ok, socket}
  end

  defp build_game_state(character, map_data, map_id, starting_position) do
    constitution = character.constitution || 10
    base_health = 100
    base_stamina = 100
    base_mana = 50

    max_health = base_health + (constitution - 10) * 5
    max_stamina = base_stamina + (character.dexterity || 10) * 2
    max_mana = base_mana + (character.intelligence || 10) * 3

    %{
      player_position: starting_position,
      map_data: map_data,
      map_id: map_id,
      character: character,
      active_panel: nil,
      player_stats: %{
        health: character.health || max_health,
        max_health: max_health,
        stamina: max_stamina,
        max_stamina: max_stamina,
        mana: character.mana || max_mana,
        max_mana: max_mana,
        level: character.level || 1,
        experience: character.experience || 0,
        next_level_exp: calculate_next_level_exp(character.level || 1),
        strength: character.strength || 10,
        dexterity: character.dexterity || 10,
        intelligence: character.intelligence || 10,
        constitution: constitution
      },
      inventory_items: load_character_inventory(character),
      equipped_weapon: load_equipped_weapon(character),
      hotbar: load_character_hotbar(character),
      quests: [],
      pending_quest_offer: nil,
      monsters: load_monsters_from_database(map_id, starting_position),
      combat: false
    }
  end

  defp build_terminal_state(starting_position, map_id) do
    initial_output = [
      "Welcome to Shard!",
      "You find yourself in a mysterious dungeon.",
      "Type 'help' for available commands.",
      ""
    ]

    terminal_output =
      if starting_position == {0, 0} and map_id == "tutorial_terrain" do
        goldie_dialogue = get_goldie_dialogue()

        initial_output ++
          ["Goldie the golden retriever wags her tail and speaks:", goldie_dialogue, ""]
      else
        initial_output
      end

    %{
      output: terminal_output,
      command_history: [],
      current_command: ""
    }
  end

  defp build_modal_state do
    %{
      show: false,
      type: 0,
      completion_message: nil
    }
  end

  defp get_goldie_dialogue do
    "Woof! Welcome to the tutorial, adventurer!\n\nI'm Goldie, your faithful guide dog. Let me help you get started on your journey.\n\nHere are some basic commands to get you moving:\n• Type 'look' to examine your surroundings\n• Use 'north', 'south', 'east', 'west' (or n/s/e/w) to move around\n• Try 'pickup \"item_name\"' to collect items you find\n• Use 'inventory' to see what you're carrying\n• Type 'help' anytime for a full list of commands\n\nThere's a key hidden somewhere to the south that might come in handy later!\nExplore around and interact with npcs, complete quests, and attack monsters.\nWhen you're ready to move to the next dungeon, unlock the locked door!\nGood luck, and remember - I'll always be here at (0,0) if you need guidance!"
  end

  def add_message(socket, message) do
    new_output = socket.assigns.terminal_state.output ++ [message] ++ [""]
    ts1 = Map.put(socket.assigns.terminal_state, :output, new_output)
    assign(socket, :terminal_state, ts1)
  end
end
