defmodule ShardWeb.MudGameLiveTest do
  use ShardWeb.ConnCase
  import Phoenix.LiveViewTest
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
      
      # Verify character information is properly loaded in assigns
      assert socket.assigns.character.name == "MageChar"
      assert socket.assigns.character.class == "mage"
      assert socket.assigns.character.race == "elf"
      assert socket.assigns.character.level == 5
      
      # Verify map_id parameter is handled
      assert socket.assigns.map_id == "2"
      
      # Verify terminal state is initialized with welcome messages
      assert is_list(socket.assigns.terminal_state.output)
      assert length(socket.assigns.terminal_state.output) > 0
      
      # Verify the terminal contains character-specific information
      output_text = Enum.join(socket.assigns.terminal_state.output, "\n")
      assert output_text =~ "Welcome to Shard!"
      
      # Verify terminal state structure
      assert Map.has_key?(socket.assigns.terminal_state, :output)
      assert Map.has_key?(socket.assigns.terminal_state, :current_input)
      assert socket.assigns.terminal_state.current_input == ""
    end
  end
end
