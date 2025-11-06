defmodule ShardWeb.UserLive.MudGameHelpers do
  @moduledoc """
  Helper functions for MudGameLive
  """

  alias Phoenix.PubSub
  alias Shard.Characters
  alias Shard.Items
  alias Shard.Npcs
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.CharacterHelpers
  #  import ShardWeb.UserLive.ItemHelpers
  import ShardWeb.UserLive.MonsterComponents

  def get_character_from_params(params) do
    case Map.get(params, "character_id") do
      nil ->
        {:error, :no_character}

      character_id ->
        try do
          character = Characters.get_character!(character_id)
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
        Shard.Repo.get!(Characters.Character, character.id)
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
    case Items.create_tutorial_key() do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
      _other -> :error
    end
  end

  defp setup_tutorial_npc do
    case Npcs.create_tutorial_npc_goldie() do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
      _other -> :error
    end
  end

  defp setup_tutorial_door do
    case Items.create_dungeon_door() do
      {:ok, _result} -> :ok
      {:error, _reason} -> :error
    end
  end

  def initialize_game_state(character, _map_id, character_name) do
    # Use the character's current zone for map generation and monster loading
    zone_id = character.current_zone_id || 1
    map_data = generate_map_from_database(zone_id)
    starting_position = get_zone_starting_position(zone_id)

    game_state = build_game_state(character, map_data, zone_id, starting_position)
    terminal_state = build_terminal_state(starting_position, zone_id)
    chat_state = build_chat_state()
    modal_state = build_modal_state()

    PubSub.subscribe(Shard.PubSub, posn_to_room_channel(game_state.player_position))

    assigns = %{
      game_state: game_state,
      terminal_state: terminal_state,
      chat_state: chat_state,
      modal_state: modal_state,
      character_name: character_name,
      active_tab: "terminal"
    }

    {:ok, assigns}
  end

  defp build_game_state(character, map_data, map_id, starting_position) do
    player_stats = build_player_stats(character)

    %{
      player_position: starting_position,
      map_data: map_data,
      map_id: map_id,
      character: character,
      active_panel: nil,
      player_stats: player_stats,
      inventory_items: load_character_inventory(character),
      equipped_weapon: load_equipped_weapon(character),
      hotbar: load_character_hotbar(character),
      quests: [],
      pending_quest_offer: nil,
      monsters: load_monsters_from_database(character.current_zone_id || 1, starting_position),
      combat: false
    }
  end

  defp build_player_stats(character) do
    constitution = character.constitution || 10
    dexterity = character.dexterity || 10
    intelligence = character.intelligence || 10
    level = character.level || 1

    max_health = calculate_max_health(constitution)
    max_stamina = calculate_max_stamina(dexterity)
    max_mana = calculate_max_mana(intelligence)

    %{
      health: character.health || max_health,
      max_health: max_health,
      stamina: max_stamina,
      max_stamina: max_stamina,
      mana: character.mana || max_mana,
      max_mana: max_mana,
      level: level,
      experience: character.experience || 0,
      next_level_exp: calculate_next_level_exp(level),
      strength: character.strength || 10,
      dexterity: dexterity,
      intelligence: intelligence,
      constitution: constitution
    }
  end

  defp calculate_max_health(constitution) do
    base_health = 100
    base_health + (constitution - 10) * 5
  end

  defp calculate_max_stamina(dexterity) do
    base_stamina = 100
    base_stamina + dexterity * 2
  end

  defp calculate_max_mana(intelligence) do
    base_mana = 50
    base_mana + intelligence * 3
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

  # Make this public so it can be called from other modules
  def build_chat_state do
    %{
      messages: [
        "Welcome to the chat!",
        "You can communicate with other players here."
      ],
      current_message: ""
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

  def add_message(terminal_state, message) do
    new_output = terminal_state.output ++ [message] ++ [""]
    Map.put(terminal_state, :output, new_output)
  end

  defp get_zone_starting_position(zone_id) do
    case Shard.Map.get_zone!(zone_id) do
      %{properties: %{"starting_room" => %{"x" => x, "y" => y}}} ->
        {x, y}

      _ ->
        # Default fallback position
        {0, 0}
    end
  end

  def posn_to_room_channel({x, y}) do
    "room:#{x},#{y}"
  end
end
