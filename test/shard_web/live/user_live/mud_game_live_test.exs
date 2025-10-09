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
  end
end
