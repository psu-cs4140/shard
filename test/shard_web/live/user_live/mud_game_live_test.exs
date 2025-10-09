defmodule ShardWeb.MudGameLiveTest do
  use ShardWeb.ConnCase
  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  alias Shard.Characters
  alias Shard.Map

  setup do
    # Create a test user
    user = user_fixture()
    
    # Create a test character
    character_attrs = %{
      name: "TestHero",
      level: 5,
      experience: 250,
      user_id: user.id
    }
    
    {:ok, character} = Characters.create_character(character_attrs)
    
    # Create a test map/room for testing
    map_id = "1"
    
    %{user: user, character: character, map_id: map_id}
  end

  describe "mount/3" do
    test "redirects when no character is provided", %{conn: conn, map_id: map_id} do
      assert {:error, {:redirect, %{to: "/maps", flash: %{"error" => "Please select a character to play"}}}} = 
        live(conn, ~p"/maps/#{map_id}/play")
    end

    test "successfully mounts with valid character", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Test that the page renders correctly
      assert html =~ "MUD Game"
      assert html =~ character.name
      assert html =~ "Level #{character.level}"
      assert html =~ "Welcome to Shard!"
      
      # Test that game state is properly initialized
      game_state = :sys.get_state(view.pid).assigns.game_state
      assert game_state.character.id == character.id
      assert game_state.player_stats.level == character.level
      assert game_state.player_stats.experience == character.experience
    end

    test "initializes with proper game state structure", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      game_state = :sys.get_state(view.pid).assigns.game_state
      
      # Test game state structure
      assert is_tuple(game_state.player_position)
      assert is_map(game_state.map_data)
      assert game_state.map_id == map_id
      assert game_state.character.id == character.id
      assert is_nil(game_state.active_panel)
      assert is_map(game_state.player_stats)
      assert is_list(game_state.inventory_items)
      assert is_map(game_state.hotbar)
      assert is_list(game_state.quests)
      assert is_nil(game_state.pending_quest_offer)
      assert is_list(game_state.monsters)
      assert game_state.combat == false
    end
  end

  describe "render/1" do
    test "renders main game interface components", %{conn: conn, character: character, map_id: map_id} do
      {:ok, _view, html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Test that main UI components are rendered
      assert html =~ "MUD Game"
      assert html =~ character.name
      assert html =~ "Level #{character.level}"
      assert html =~ "Game Controls"
      assert html =~ "Character Sheet"
      assert html =~ "Inventory"
      assert html =~ "Quests"
      assert html =~ "Map"
      assert html =~ "Settings"
      assert html =~ "MUD Game v1.0"
    end

    test "renders player stats correctly", %{conn: conn, character: character, map_id: map_id} do
      {:ok, _view, html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Test that player stats are displayed
      assert html =~ "100" # Health values
      assert html =~ "Level #{character.level}"
    end

    test "renders terminal with welcome message", %{conn: conn, character: character, map_id: map_id} do
      {:ok, _view, html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Test that terminal shows welcome messages
      assert html =~ "Welcome to Shard!"
      assert html =~ "You find yourself in a mysterious dungeon."
      assert html =~ "Type &#39;help&#39; for available commands."
    end
  end

  describe "handle_event/3 - modal events" do
    test "open_modal event shows character sheet", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Test opening character sheet modal
      view |> element("button", "Character Sheet") |> render_click()
      
      modal_state = :sys.get_state(view.pid).assigns.modal_state
      assert modal_state.show == true
      assert modal_state.type == "character_sheet"
    end

    test "open_modal event shows inventory", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Test opening inventory modal
      view |> element("button", "Inventory") |> render_click()
      
      modal_state = :sys.get_state(view.pid).assigns.modal_state
      assert modal_state.show == true
      assert modal_state.type == "inventory"
    end

    test "hide_modal event closes modal", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # First open a modal
      view |> element("button", "Character Sheet") |> render_click()
      
      # Verify it's open
      modal_state = :sys.get_state(view.pid).assigns.modal_state
      assert modal_state.show == true
      
      # Now close it
      render_hook(view, "hide_modal", %{})
      
      modal_state = :sys.get_state(view.pid).assigns.modal_state
      assert modal_state.show == false
      assert modal_state.type == ""
    end
  end

  describe "handle_event/3 - command events" do
    test "submit_command processes valid command", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Submit a help command
      view |> form("form", command: %{text: "help"}) |> render_submit()
      
      terminal_state = :sys.get_state(view.pid).assigns.terminal_state
      
      # Check that command was added to history
      assert "> help" in terminal_state.output
      assert "help" in terminal_state.command_history
      assert terminal_state.current_command == ""
    end

    test "submit_command ignores empty commands", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      initial_output_length = length(:sys.get_state(view.pid).assigns.terminal_state.output)
      
      # Submit empty command
      view |> form("form", command: %{text: "   "}) |> render_submit()
      
      terminal_state = :sys.get_state(view.pid).assigns.terminal_state
      
      # Check that nothing was added
      assert length(terminal_state.output) == initial_output_length
      assert terminal_state.command_history == []
    end

    test "update_command updates current command text", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Update command text
      render_hook(view, "update_command", %{"command" => %{"text" => "test command"}})
      
      terminal_state = :sys.get_state(view.pid).assigns.terminal_state
      assert terminal_state.current_command == "test command"
    end
  end

  describe "handle_event/3 - keypress events" do
    test "keypress handles arrow key movement", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      initial_position = :sys.get_state(view.pid).assigns.game_state.player_position
      
      # Send arrow key press
      render_hook(view, "keypress", %{"key" => "ArrowUp"})
      
      # Check that some response was generated (movement or blocked movement)
      terminal_state = :sys.get_state(view.pid).assigns.terminal_state
      assert length(terminal_state.output) > 4 # More than initial welcome messages
    end

    test "keypress ignores non-movement keys", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      initial_output_length = length(:sys.get_state(view.pid).assigns.terminal_state.output)
      
      # Send non-movement key
      render_hook(view, "keypress", %{"key" => "a"})
      
      terminal_state = :sys.get_state(view.pid).assigns.terminal_state
      
      # Check that nothing was added to output
      assert length(terminal_state.output) == initial_output_length
    end
  end

  describe "handle_event/3 - exit click events" do
    test "click_exit moves player when valid direction", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Click an exit direction
      render_hook(view, "click_exit", %{"dir" => "north"})
      
      # Check that some movement message was generated
      terminal_state = :sys.get_state(view.pid).assigns.terminal_state
      assert length(terminal_state.output) > 4 # More than initial welcome messages
    end
  end

  describe "handle_info/2" do
    test "handles noise messages", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      initial_output_length = length(:sys.get_state(view.pid).assigns.terminal_state.output)
      
      # Send noise message
      send(view.pid, {:noise, "You hear a distant roar."})
      
      # Wait for the message to be processed
      :timer.sleep(10)
      
      terminal_state = :sys.get_state(view.pid).assigns.terminal_state
      
      # Check that message was added
      assert length(terminal_state.output) > initial_output_length
      assert "You hear a distant roar." in terminal_state.output
    end

    test "handles area heal messages and updates health", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # First reduce health to test healing
      game_state = :sys.get_state(view.pid).assigns.game_state
      reduced_health_state = put_in(game_state, [:player_stats, :health], 50)
      :sys.replace_state(view.pid, fn state -> 
        %{state | assigns: %{state.assigns | game_state: reduced_health_state}}
      end)
      
      # Send area heal message
      send(view.pid, {:area_heal, 5, "A healing aura surrounds you."})
      
      # Wait for the message to be processed
      :timer.sleep(10)
      
      updated_game_state = :sys.get_state(view.pid).assigns.game_state
      terminal_state = :sys.get_state(view.pid).assigns.terminal_state
      
      # Check that health was increased
      assert updated_game_state.player_stats.health == 55
      assert "A healing aura surrounds you." in terminal_state.output
      assert "Area heal effect: 5 damage healed" in terminal_state.output
    end

    test "area heal doesn't exceed max health", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      # Health should already be at max (100)
      initial_game_state = :sys.get_state(view.pid).assigns.game_state
      assert initial_game_state.player_stats.health == 100
      
      # Send area heal message
      send(view.pid, {:area_heal, 5, "A healing aura surrounds you."})
      
      # Wait for the message to be processed
      :timer.sleep(10)
      
      updated_game_state = :sys.get_state(view.pid).assigns.game_state
      
      # Health should remain at 100
      assert updated_game_state.player_stats.health == 100
    end
  end

  describe "helper function add_message/2" do
    test "adds message to terminal output", %{conn: conn, character: character, map_id: map_id} do
      {:ok, view, _html} = 
        live(conn, ~p"/maps/#{map_id}/play?character_id=#{character.id}&character_name=#{URI.encode(character.name)}")
      
      initial_output_length = length(:sys.get_state(view.pid).assigns.terminal_state.output)
      
      # Use the add_message function indirectly through noise message
      send(view.pid, {:noise, "Test message"})
      
      # Wait for the message to be processed
      :timer.sleep(10)
      
      terminal_state = :sys.get_state(view.pid).assigns.terminal_state
      
      # Check that message was added
      assert length(terminal_state.output) > initial_output_length
      assert "Test message" in terminal_state.output
    end
  end
end
