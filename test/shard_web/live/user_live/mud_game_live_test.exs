defmodule ShardWeb.MudGameLiveTest do
  use ShardWeb.ConnCase
  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  describe "terminal component rendering" do
    test "renders terminal with initial output", %{conn: conn} do
      user = user_fixture()
      character = character_fixture(%{user_id: user.id, name: "TestChar", level: 1})
      
      conn = log_in_user(conn, user)
      
      {:ok, view, _html} = live(conn, ~p"/maps/1/play?character_id=#{character.id}")
      
      # Check that the terminal component renders with welcome messages
      assert render(view) =~ "Welcome to Shard!"
      assert render(view) =~ "You find yourself in a mysterious dungeon."
      assert render(view) =~ "Type 'help' for available commands."
    end
  end

  # Helper function to create a test character
  defp character_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "TestCharacter",
      level: 1,
      experience: 0,
      user_id: 1
    }
    
    attrs = Enum.into(attrs, default_attrs)
    
    {:ok, character} = Shard.Characters.create_character(attrs)
    character
  end
end
