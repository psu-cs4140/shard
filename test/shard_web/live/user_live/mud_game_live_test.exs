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
      
      # Use live_isolated to test the LiveView in isolation
      {:ok, view, _html} = live_isolated(conn, ShardWeb.MudGameLive, 
        session: %{"current_scope" => %{user: user}},
        connect_params: %{"map_id" => "1", "character_id" => to_string(character.id)}
      )
      
      # Check that the terminal component renders with welcome messages
      html = render(view)
      assert html =~ "Welcome to Shard!"
      assert html =~ "You find yourself in a mysterious dungeon."
      assert html =~ "Type 'help' for available commands."
    end
  end
end
