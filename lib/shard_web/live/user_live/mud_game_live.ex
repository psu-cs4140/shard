defmodule ShardWeb.MudGameLive do
  use ShardWeb, :live_view
  alias Phoenix.PubSub
  alias Phoenix.LiveView.JS
  import ShardWeb.UserLive.Components
  import ShardWeb.UserLive.Components2
  import ShardWeb.UserLive.MapHelpers
  import ShardWeb.UserLive.Movement
  import ShardWeb.UserLive.Commands1
  import ShardWeb.UserLive.MapComponents
  import ShardWeb.UserLive.LegacyMap
  import ShardWeb.UserLive.MonsterComponents
  import ShardWeb.UserLive.CharacterHelpers
  import ShardWeb.UserLive.ItemHelpers

  @impl true
  def mount(%{"map_id" => map_id} = params, _session, socket) do
    # Get character if provided
    character =
      case Map.get(params, "character_id") do
        nil ->
          nil

        character_id ->
          try do
            Shard.Characters.get_character!(character_id)
          rescue
            _ -> nil
          end
      end

    # Get character name from URL parameter (fallback to character.name if available)
    character_name =
      case Map.get(params, "character_name") do
        nil -> if character, do: character.name, else: "Unknown"
        name -> URI.decode(name)
      end

    # If no character provided or character not found, redirect to character selection
    if is_nil(character) do
      {:ok,
       socket
       |> put_flash(:error, "Please select a character to play")
       |> push_navigate(to: ~p"/maps")}
    else
      # Load character with associations
      character =
        try do
          Shard.Repo.get!(Shard.Characters.Character, character.id)
          |> Shard.Repo.preload([:character_inventories, :hotbar_slots])
        rescue
          _ -> character
        end

      # Generate map data based on selected map
      map_data = generate_map_from_database(map_id)

      # Create tutorial key if entering tutorial terrain
      if map_id == "tutorial_terrain" do
        case Shard.Items.create_tutorial_key() do
          {:ok, _result} ->
            :ok

          {:error, _reason} ->
            :error

          _other ->
            :error
        end
      end

      # Create Goldie the golden retriever NPC if entering tutorial terrain
      if map_id == "tutorial_terrain" do
        case Shard.Npcs.create_tutorial_npc_goldie() do
          {:ok, _result} ->
            :ok

          {:error, _reason} ->
            :error

          _other ->
            :error
        end
      end

      # Create dungeon door for tutorial terrain
      if map_id == "tutorial_terrain" do
        case Shard.Items.create_dungeon_door() do
          {:ok, _result} ->
            :ok

          {:error, _reason} ->
            :error

          _other ->
            :error
        end
      end

      # Find a valid starting position (first floor tile found)
      starting_position = find_valid_starting_position(map_data)

      # Store the map_id and character for later use
      map_id = map_id

      # Initialize game state with character stats from database
      # Calculate max values based on character attributes
      base_health = 100
      base_stamina = 100
      base_mana = 50

      # Calculate max stats based on character attributes
      constitution = character.constitution || 10
      max_health = base_health + (constitution - 10) * 5
      max_stamina = base_stamina + (character.dexterity || 10) * 2
      max_mana = base_mana + (character.intelligence || 10) * 3

      game_state = %{
        player_position: starting_position,
        map_data: map_data,
        map_id: map_id,
        character: character,
        active_panel: nil,
        player_stats: %{
          health: character.health || max_health,
          max_health: max_health,
          # Always start with full stamina
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
        # Stores quest offer waiting for acceptance/denial
        pending_quest_offer: nil,

        # Load monsters from database
        monsters: load_monsters_from_database(map_id, starting_position),
        combat: false
      }

      # Check if player is at Goldie's location (0,0) and add her dialogue
      initial_output = [
        "Welcome to Shard!",
        "You find yourself in a mysterious dungeon.",
        "Type 'help' for available commands.",
        ""
      ]

      terminal_output = 
        if starting_position == {0, 0} and map_id == "tutorial_terrain" do
          # Get Goldie's dialogue and add it to the output
          goldie_dialogue = "Woof! Welcome to the tutorial, adventurer!\n\nI'm Goldie, your faithful guide dog. Let me help you get started on your journey.\n\nHere are some basic commands to get you moving:\n• Type 'look' to examine your surroundings\n• Use 'north', 'south', 'east', 'west' (or n/s/e/w) to move around\n• Try 'pickup \"item_name\"' to collect items you find\n• Use 'inventory' to see what you're carrying\n• Type 'help' anytime for a full list of commands\n\nThere's a key hidden somewhere to the south that might come in handy later!\nGood luck, and remember - I'll always be here at (0,0) if you need guidance!"
          
          initial_output ++ [
            "Goldie the golden retriever wags her tail and speaks:",
            goldie_dialogue,
            ""
          ]
        else
          initial_output
        end

      terminal_state = %{
        output: terminal_output,
        command_history: [],
        current_command: ""
      }

      # Controls what modal popup we are showing
      modal_state = %{
        show: false,
        type: 0
      }

      PubSub.subscribe(
        Shard.PubSub,
        posn_to_room_channel(game_state.player_position)
      )

      {:ok,
       assign(socket,
         game_state: game_state,
         terminal_state: terminal_state,
         modal_state: modal_state,
         available_exits: compute_available_exits(game_state.player_position),
         character_name: character_name
       )}
    end
  end

  @impl true
  @spec render(any()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-screen bg-gray-900 text-white" phx-window-keydown="keypress">
      <!-- "phx-window-keydown="keypress" -->
      <!-- Header -->
      <header class="bg-gray-800 p-4 shadow-lg flex justify-between items-center">
        <h1 class="text-2xl font-bold">MUD Game</h1>
        <div class="text-right">
          <div class="text-lg font-semibold text-green-400">
            {@character_name}
          </div>
          <div class="text-sm text-gray-400">
            Level {@game_state.player_stats.level}
          </div>
        </div>
      </header>
      
    <!-- Main Content -->
      <div class="flex flex-1 overflow-hidden">
        <!-- Left Panel - Terminal -->
        <div class="flex-1 p-4 flex flex-col">
          <.terminal terminal_state={@terminal_state} />
        </div>
        
    <!-- Right Panel - Controls -->
        <div class="w-100 bg-gray-800 px-4 py-4 flex flex-col space-y-4 overflow-y-auto">
          <.minimap
            map_data={@game_state.map_data}
            player_position={@game_state.player_position}
          />

          <.player_stats
            stats={@game_state.player_stats}
            hotbar={@game_state.hotbar}
          />

          <h2 class="text-xl font-semibold mb-4">Game Controls</h2>

          <.control_button
            text="Character Sheet"
            icon="hero-user"
            click={JS.push("open_modal")}
            value="character_sheet"
          />

          <.control_button
            text="Inventory"
            icon="hero-shopping-bag"
            click={JS.push("open_modal")}
            value="inventory"
          />

          <.control_button
            text="Quests"
            icon="hero-document-text"
            click={JS.push("open_modal")}
            value="quests"
          />

          <.control_button
            text="Map"
            icon="hero-map"
            click={JS.push("open_modal")}
            value="map"
          />

          <.control_button
            text="Settings"
            icon="hero-cog"
            click={JS.push("open_modal")}
            value="settings"
          />

          <%!-- This is used to show char sheet, inventory, etc --%>
          <.character_sheet
            :if={@modal_state.show && @modal_state.type == "character_sheet"}
            game_state={@game_state}
          />

          <.inventory
            :if={@modal_state.show && @modal_state.type == "inventory"}
            game_state={@game_state}
          />

          <.quests :if={@modal_state.show && @modal_state.type == "quests"} game_state={@game_state} />

          <.map :if={@modal_state.show && @modal_state.type == "map"} game_state={@game_state} />

          <.settings
            :if={@modal_state.show && @modal_state.type == "settings"}
            game_state={@game_state}
          />
        </div>
      </div>
      
    <!-- Footer -->
      <footer class="bg-gray-800 p-2 text-center text-sm">
        <p>MUD Game v1.0</p>
      </footer>
    </div>
    """
  end

  @impl true
  def handle_event("open_modal", %{"modal" => modal_type}, socket) do
    {:noreply, assign(socket, modal_state: %{show: true, type: modal_type})}
  end

  def handle_event("hide_modal", _params, socket) do
    {:noreply, assign(socket, modal_state: %{show: false, type: ""})}
  end

  # Handle keypresses for navigation, inventory, etc.
  def handle_event("keypress", %{"key" => key}, socket) do
    # Check if it's a movement key
    case key do
      arrow_key when arrow_key in ["ArrowUp", "ArrowDown", "ArrowLeft", "ArrowRight"] ->
        # Use the same execute_movement function that terminal commands use
        {response, updated_game_state} = execute_movement(socket.assigns.game_state, arrow_key)

        # Add the response to terminal output
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)

        {:noreply,
         assign(socket,
           game_state: updated_game_state,
           terminal_state: terminal_state,
           available_exits: compute_available_exits(updated_game_state.player_position)
         )}

      _ ->
        # Non-movement key, do nothing
        {:noreply, socket}
    end
  end

  def handle_event("submit_command", %{"command" => %{"text" => command_text}}, socket) do
    trimmed_command = String.trim(command_text)

    if trimmed_command != "" do
      # Add command to history
      new_history = [trimmed_command | socket.assigns.terminal_state.command_history]

      # Process the command and get response and updated game state
      {response, updated_game_state} = process_command(trimmed_command, socket.assigns.game_state)

      # Check if stats changed significantly and save to database
      old_stats = socket.assigns.game_state.player_stats
      new_stats = updated_game_state.player_stats

      if stats_changed_significantly?(old_stats, new_stats) do
        save_character_stats(updated_game_state.character, new_stats)
      end

      # Add command and response to output
      new_output =
        socket.assigns.terminal_state.output ++
          ["> #{trimmed_command}"] ++
          response ++
          [""]

      terminal_state = %{
        output: new_output,
        command_history: new_history,
        current_command: ""
      }

      {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("update_command", %{"command" => %{"text" => command_text}}, socket) do
    terminal_state = Map.put(socket.assigns.terminal_state, :current_command, command_text)
    {:noreply, assign(socket, terminal_state: terminal_state)}
  end

  def handle_event("save_character_stats", _params, socket) do
    # Manually save character stats to database
    case save_character_stats(
           socket.assigns.game_state.character,
           socket.assigns.game_state.player_stats
         ) do
      {:ok, _character} ->
        socket = add_message(socket, "Character stats saved successfully.")
        {:noreply, socket}

      {:error, _error} ->
        socket = add_message(socket, "Failed to save character stats.")
        {:noreply, socket}
    end
  end

  def handle_event("use_hotbar_item", %{"slot" => slot_number}, socket) do
    slot_key = String.to_atom("slot_#{slot_number}")
    item = Map.get(socket.assigns.game_state.hotbar, slot_key)

    case item do
      nil ->
        socket = add_message(socket, "Hotbar slot #{slot_number} is empty.")
        {:noreply, socket}

      item ->
        {response, updated_game_state} = use_item(socket.assigns.game_state, item)

        # Add response to terminal
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)

        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}
    end
  end

  def handle_event("equip_item", %{"item_id" => item_id}, socket) do
    # Find item in inventory
    item =
      Enum.find(socket.assigns.game_state.inventory_items, fn inv_item ->
        to_string(Map.get(inv_item, :id)) == item_id
      end)

    case item do
      nil ->
        socket = add_message(socket, "Item not found in inventory.")
        {:noreply, socket}

      item ->
        {response, updated_game_state} = equip_item(socket.assigns.game_state, item)

        # Add response to terminal
        new_output = socket.assigns.terminal_state.output ++ response ++ [""]
        terminal_state = Map.put(socket.assigns.terminal_state, :output, new_output)

        {:noreply, assign(socket, game_state: updated_game_state, terminal_state: terminal_state)}
    end
  end

  # (C) Handle clicking an exit button to move rooms
  @impl true
  def handle_event("click_exit", %{"dir" => dir}, socket) do
    key = dir_to_key(dir)
    player_position = socket.assigns.game_state.player_position
    map_data = socket.assigns.game_state.map_data

    new_position =
      case key do
        nil -> player_position
        _ -> calc_position(player_position, key, map_data)
      end

    terminal_state =
      if new_position != player_position do
        msg = "You move #{dir}."
        Map.update!(socket.assigns.terminal_state, :output, &(&1 ++ [msg, ""]))
      else
        socket.assigns.terminal_state
      end

    game_state = %{
      socket.assigns.game_state
      | player_position: new_position
    }

    {:noreply,
     assign(socket,
       game_state: game_state,
       terminal_state: terminal_state,
       available_exits: compute_available_exits(game_state.player_position)
     )}
  end

  def add_message(socket, message) do
    new_output = socket.assigns.terminal_state.output ++ [message] ++ [""]
    ts1 = Map.put(socket.assigns.terminal_state, :output, new_output)
    assign(socket, :terminal_state, ts1)
  end

  @impl true
  def handle_info({:noise, text}, socket) do
    socket = add_message(socket, text)
    {:noreply, socket}
  end

  def handle_info({:area_heal, xx, msg}, socket) do
    socket =
      socket
      |> add_message(msg)
      |> add_message("Area heal effect: #{xx} damage healed")

    current_stats = socket.assigns.game_state.player_stats
    max_health = current_stats.max_health
    current_health = current_stats.health

    if current_health < max_health do
      new_health = min(current_health + xx, max_health)

      updated_stats = %{current_stats | health: new_health}
      updated_game_state = %{socket.assigns.game_state | player_stats: updated_stats}

      # Save updated stats to database
      save_character_stats(socket.assigns.game_state.character, updated_stats)

      {:noreply, assign(socket, :game_state, updated_game_state)}
    else
      {:noreply, socket}
    end
  end
end
