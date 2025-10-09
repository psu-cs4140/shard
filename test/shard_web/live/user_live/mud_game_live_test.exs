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
        class: "warrior"
      }
      character = Shard.Repo.insert!(character)
      
      conn = log_in_user(conn, user)
      
      {:ok, view, _html} = live(conn, "/maps/1/play?character_id=#{character.id}")
      
      # Check that the terminal component renders with welcome messages
      assert render(view) =~ "Welcome to Shard!"
      assert render(view) =~ "You find yourself in a mysterious dungeon."
      assert render(view) =~ "Type 'help' for available commands."
    end
  end
end
