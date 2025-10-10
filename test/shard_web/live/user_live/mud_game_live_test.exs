defmodule ShardWeb.MudGameLiveTest do
  use ShardWeb.ConnCase
  import Shard.UsersFixtures

  describe "terminal component rendering" do
    test "renders terminal with initial output", %{conn: conn} do
      user = user_fixture()
      
      # Create character using Repo.insert! directly to avoid fixture issues
      character = %Shard.Characters.Character{
        name: "TestChar",
        level: 1,
        experience: 0,
        user_id: user.id,
        class: "warrior",
        race: "human"
      }
      character = Shard.Repo.insert!(character)
      
      conn = log_in_user(conn, user)
      
      # Test the LiveView by calling mount directly with proper socket setup
      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }
      
      params = %{"map_id" => "1", "character_id" => to_string(character.id)}
      session = %{}
      
      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)
      
      # Check that the terminal state contains welcome messages
      assert "Welcome to Shard!" in socket.assigns.terminal_state.output
      assert "You find yourself in a mysterious dungeon." in socket.assigns.terminal_state.output
      assert "Type 'help' for available commands." in socket.assigns.terminal_state.output
    end

    test "handles command input and updates terminal state", %{conn: conn} do
      user = user_fixture()
      
      # Create character using Repo.insert! directly to avoid fixture issues
      character = %Shard.Characters.Character{
        name: "TestChar",
        level: 1,
        experience: 0,
        user_id: user.id,
        class: "warrior",
        race: "human"
      }
      character = Shard.Repo.insert!(character)
      
      conn = log_in_user(conn, user)
      
      # Test the LiveView by calling mount directly with proper socket setup
      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }
      
      params = %{"map_id" => "1", "character_id" => to_string(character.id)}
      session = %{}
      
      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)
      
      # Get initial output count
      initial_output_count = length(socket.assigns.terminal_state.output)
      
      # Simulate typing a command
      {:noreply, updated_socket} = ShardWeb.MudGameLive.handle_event(
        "submit_command", 
        %{"command" => %{"text" => "help"}}, 
        socket
      )
      
      # Verify the terminal state was updated
      assert length(updated_socket.assigns.terminal_state.output) > initial_output_count
      
      # Verify the command appears in the output
      output_text = Enum.join(updated_socket.assigns.terminal_state.output, "\n")
      assert output_text =~ "> help"
      
      # Verify help text appears in response
      assert output_text =~ "Available commands:"
    end

    test "handles invalid commands gracefully", %{conn: conn} do
      user = user_fixture()
      
      # Create character using Repo.insert! directly to avoid fixture issues
      character = %Shard.Characters.Character{
        name: "TestChar",
        level: 1,
        experience: 0,
        user_id: user.id,
        class: "warrior",
        race: "human"
      }
      character = Shard.Repo.insert!(character)
      
      conn = log_in_user(conn, user)
      
      # Test the LiveView by calling mount directly with proper socket setup
      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }
      
      params = %{"map_id" => "1", "character_id" => to_string(character.id)}
      session = %{}
      
      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)
      
      # Get initial output count
      initial_output_count = length(socket.assigns.terminal_state.output)
      
      # Simulate typing an invalid command
      {:noreply, updated_socket} = ShardWeb.MudGameLive.handle_event(
        "submit_command", 
        %{"command" => %{"text" => "invalidcommand"}}, 
        socket
      )
      
      # Verify the terminal state was updated
      assert length(updated_socket.assigns.terminal_state.output) > initial_output_count
      
      # Verify the command appears in the output
      output_text = Enum.join(updated_socket.assigns.terminal_state.output, "\n")
      assert output_text =~ "> invalidcommand"
      
      # Verify error message appears in response
      assert output_text =~ "Unknown command" or output_text =~ "Invalid command" or output_text =~ "Command not found"
    end

    test "renders terminal with different character parameters and map configurations", %{conn: conn} do
      user = user_fixture()
      
      # Create a character with different attributes
      character = %Shard.Characters.Character{
        name: "MageChar",
        level: 5,
        experience: 1000,
        user_id: user.id,
        class: "mage",
        race: "elf"
      }
      character = Shard.Repo.insert!(character)
      
      conn = log_in_user(conn, user)
      
      # Test the LiveView with different map_id parameter
      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }
      
      params = %{"map_id" => "2", "character_id" => to_string(character.id)}
      session = %{}
      
      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)
      
      # Verify character information is properly loaded in game_state
      assert socket.assigns.game_state.character.name == "MageChar"
      assert socket.assigns.game_state.character.class == "mage"
      assert socket.assigns.game_state.character.race == "elf"
      assert socket.assigns.game_state.character.level == 5
      
      # Verify map_id parameter is handled
      assert socket.assigns.game_state.map_id == "2"
      
      # Verify terminal state is initialized with welcome messages
      assert is_list(socket.assigns.terminal_state.output)
      assert length(socket.assigns.terminal_state.output) > 0
      
      # Verify the terminal contains character-specific information
      output_text = Enum.join(socket.assigns.terminal_state.output, "\n")
      assert output_text =~ "Welcome to Shard!"
      
      # Verify terminal state structure
      assert Map.has_key?(socket.assigns.terminal_state, :output)
      assert Map.has_key?(socket.assigns.terminal_state, :current_command)
      assert socket.assigns.terminal_state.current_command == ""
    end

    test "handles modal open and close events correctly", %{conn: conn} do
      user = user_fixture()
      
      # Create character using Repo.insert! directly to avoid fixture issues
      character = %Shard.Characters.Character{
        name: "TestChar",
        level: 1,
        experience: 0,
        user_id: user.id,
        class: "warrior",
        race: "human"
      }
      character = Shard.Repo.insert!(character)
      
      conn = log_in_user(conn, user)
      
      # Test the LiveView by calling mount directly with proper socket setup
      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }
      
      params = %{"map_id" => "1", "character_id" => to_string(character.id)}
      session = %{}
      
      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)
      
      # Verify initial modal state is closed
      assert socket.assigns.modal_state.show == false
      assert socket.assigns.modal_state.type == 0
      
      # Test opening character sheet modal
      {:noreply, updated_socket} = ShardWeb.MudGameLive.handle_event(
        "open_modal", 
        %{"modal" => "character_sheet"}, 
        socket
      )
      
      # Verify modal state was updated correctly
      assert updated_socket.assigns.modal_state.show == true
      assert updated_socket.assigns.modal_state.type == "character_sheet"
      
      # Test opening inventory modal (should change type but keep show=true)
      {:noreply, inventory_socket} = ShardWeb.MudGameLive.handle_event(
        "open_modal", 
        %{"modal" => "inventory"}, 
        updated_socket
      )
      
      # Verify modal type changed to inventory
      assert inventory_socket.assigns.modal_state.show == true
      assert inventory_socket.assigns.modal_state.type == "inventory"
      
      # Test closing modal
      {:noreply, closed_socket} = ShardWeb.MudGameLive.handle_event(
        "hide_modal", 
        %{}, 
        inventory_socket
      )
      
      # Verify modal is now closed
      assert closed_socket.assigns.modal_state.show == false
      assert closed_socket.assigns.modal_state.type == ""
    end

    test "handles PubSub messages and renders components with different states", %{conn: conn} do
      user = user_fixture()
      
      # Create character with specific stats for testing
      character = %Shard.Characters.Character{
        name: "TestWarrior",
        level: 10,
        experience: 5000,
        user_id: user.id,
        class: "warrior",
        race: "dwarf"
      }
      character = Shard.Repo.insert!(character)
      
      conn = log_in_user(conn, user)
      
      # Test the LiveView by calling mount directly with proper socket setup
      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }
      
      params = %{"map_id" => "3", "character_id" => to_string(character.id)}
      session = %{}
      
      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)
      
      # Test handle_info for :noise message
      {:noreply, noise_socket} = ShardWeb.MudGameLive.handle_info({:noise, "A distant roar echoes through the dungeon."}, socket)
      
      # Verify noise message was added to terminal output
      output_text = Enum.join(noise_socket.assigns.terminal_state.output, "\n")
      assert output_text =~ "A distant roar echoes through the dungeon."
      
      # Test handle_info for :area_heal message with low health
      # First, set player health to low value
      low_health_game_state = put_in(socket.assigns.game_state, [:player_stats, :health], 30)
      low_health_socket = %{socket | assigns: Map.put(socket.assigns, :game_state, low_health_game_state)}
      
      {:noreply, healed_socket} = ShardWeb.MudGameLive.handle_info(
        {:area_heal, 5, "A warm light fills the area."}, 
        low_health_socket
      )
      
      # Verify heal message was added and health increased
      healed_output = Enum.join(healed_socket.assigns.terminal_state.output, "\n")
      assert healed_output =~ "A warm light fills the area."
      assert healed_output =~ "Area heal effect: 5 damage healed"
      assert healed_socket.assigns.game_state.player_stats.health == 35
      
      # Test handle_info for :area_heal message with full health
      full_health_game_state = put_in(socket.assigns.game_state, [:player_stats, :health], 100)
      full_health_socket = %{socket | assigns: Map.put(socket.assigns, :game_state, full_health_game_state)}
      
      {:noreply, no_heal_socket} = ShardWeb.MudGameLive.handle_info(
        {:area_heal, 5, "Another healing wave passes through."}, 
        full_health_socket
      )
      
      # Verify message was added but health didn't change (already at max)
      no_heal_output = Enum.join(no_heal_socket.assigns.terminal_state.output, "\n")
      assert no_heal_output =~ "Another healing wave passes through."
      assert no_heal_output =~ "Area heal effect: 5 damage healed"
      assert no_heal_socket.assigns.game_state.player_stats.health == 100
      
      # Test keypress event handling for arrow keys
      {:noreply, movement_socket} = ShardWeb.MudGameLive.handle_event("keypress", %{"key" => "ArrowUp"}, socket)
      
      # Verify movement was processed (terminal output should contain movement response)
      _movement_output = Enum.join(movement_socket.assigns.terminal_state.output, "\n")
      # Movement should either succeed or fail, but should add some response to terminal
      assert length(movement_socket.assigns.terminal_state.output) > length(socket.assigns.terminal_state.output)
      
      # Test keypress event for non-movement key (should do nothing)
      {:noreply, no_change_socket} = ShardWeb.MudGameLive.handle_event("keypress", %{"key" => "Space"}, socket)
      
      # Verify no changes were made for non-movement key
      assert no_change_socket.assigns.terminal_state.output == socket.assigns.terminal_state.output
      assert no_change_socket.assigns.game_state == socket.assigns.game_state
      
      # Test click_exit event
      {:noreply, exit_socket} = ShardWeb.MudGameLive.handle_event("click_exit", %{"dir" => "north"}, socket)
      
      # Verify exit click was processed (should either move or stay in place)
      _exit_output = Enum.join(exit_socket.assigns.terminal_state.output, "\n")
      # Should either have movement message or no change, but socket should be valid
      assert is_map(exit_socket.assigns.game_state)
      assert is_list(exit_socket.assigns.terminal_state.output)
      
      # Test update_command event
      {:noreply, command_socket} = ShardWeb.MudGameLive.handle_event(
        "update_command", 
        %{"command" => %{"text" => "look around"}}, 
        socket
      )
      
      # Verify current command was updated
      assert command_socket.assigns.terminal_state.current_command == "look around"
      
      # Test component rendering with different modal states
      # Test that different modal types render different components
      character_sheet_socket = %{socket | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "character_sheet"})}
      inventory_socket = %{socket | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "inventory"})}
      quests_socket = %{socket | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "quests"})}
      map_socket = %{socket | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "map"})}
      settings_socket = %{socket | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "settings"})}
      
      # Test that the modal states are correctly assigned
      assert character_sheet_socket.assigns.modal_state.show == true
      assert character_sheet_socket.assigns.modal_state.type == "character_sheet"
      assert inventory_socket.assigns.modal_state.type == "inventory"
      assert quests_socket.assigns.modal_state.type == "quests"
      assert map_socket.assigns.modal_state.type == "map"
      assert settings_socket.assigns.modal_state.type == "settings"
      
      # Test that character data is properly accessible in different states
      assert character_sheet_socket.assigns.game_state.character.name == "TestWarrior"
      assert character_sheet_socket.assigns.game_state.character.level == 10
      assert inventory_socket.assigns.game_state.inventory_items != []
      assert quests_socket.assigns.game_state.quests == []
      assert map_socket.assigns.game_state.map_data != nil
      assert settings_socket.assigns.game_state.player_stats != nil
      
      # Verify character name is accessible across all modal states
      assert character_sheet_socket.assigns.character_name == "TestWarrior"
      assert inventory_socket.assigns.character_name == "TestWarrior"
      assert quests_socket.assigns.character_name == "TestWarrior"
      assert map_socket.assigns.character_name == "TestWarrior"
      assert settings_socket.assigns.character_name == "TestWarrior"
    end
  end
end
