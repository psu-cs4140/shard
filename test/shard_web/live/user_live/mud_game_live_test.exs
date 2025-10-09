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
  end
end
