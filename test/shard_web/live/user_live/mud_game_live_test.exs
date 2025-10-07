defmodule ShardWeb.MudGameLiveTest do
  use ShardWeb.ConnCase
  import Phoenix.LiveViewTest
  alias Shard.Characters
  alias Shard.Repo

  @map_id "test_map"

  describe "mount/3" do
    setup do
      # Create a test user
      user = 
        %Shard.Users.User{}
        |> Shard.Users.User.registration_changeset(%{
          email: "test@example.com",
          password: "password123"
        })
        |> Repo.insert!()

      # Create a test character
      character_attrs = %{
        name: "Test Character",
        level: 1,
        experience: 0,
        user_id: user.id
      }

      {:ok, character} = Characters.create_character(character_attrs)

      %{
        user: user,
        character: character
      }
    end

    test "redirects when no character is provided", %{conn: conn} do
      {:error, {:redirect, %{to: "/maps"}}} = live(conn, ~p"/play/#{@map_id}")
    end

    test "successfully mounts when character is provided", %{conn: conn, character: character} do
      {:ok, view, _html} = live(conn, ~p"/play/#{@map_id}?character_id=#{character.id}&character_name=Test%20Character")
      
      # Check that the game state is initialized
      assert render(view) =~ "MUD Game"
      assert render(view) =~ character.name
    end

    test "uses character name from URL parameter", %{conn: conn, character: character} do
      custom_name = "Custom Name"
      encoded_name = URI.encode(custom_name)
      
      {:ok, view, _html} = live(conn, ~p"/play/#{@map_id}?character_id=#{character.id}&character_name=#{encoded_name}")
      
      assert render(view) =~ custom_name
    end

    test "falls back to character name when URL parameter missing", %{conn: conn, character: character} do
      {:ok, view, _html} = live(conn, ~p"/play/#{@map_id}?character_id=#{character.id}")
      
      assert render(view) =~ character.name
    end
  end

  describe "render/1" do
    setup do
      user = 
        %Shard.Users.User{}
        |> Shard.Users.User.registration_changeset(%{
          email: "test2@example.com",
          password: "password123"
        })
        |> Repo.insert!()

      character_attrs = %{
        name: "Test Character",
        level: 5,
        experience: 500,
        user_id: user.id
      }

      {:ok, character} = Characters.create_character(character_attrs)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/play/#{@map_id}?character_id=#{character.id}&character_name=Test%20Character")

      %{
        view: view,
        character: character
      }
    end

    test "renders header with character info", %{view: view, character: character} do
      html = render(view)
      assert html =~ "MUD Game"
      assert html =~ character.name
      assert html =~ "Level #{character.level}"
    end

    test "renders terminal component", %{view: view} do
      html = render(view)
      assert html =~ "Welcome to Shard!"
      assert html =~ "You find yourself in a mysterious dungeon."
    end

    test "renders minimap component", %{view: view} do
      html = render(view)
      assert html =~ "Minimap"
    end

    test "renders player stats component", %{view: view} do
      html = render(view)
      assert html =~ "Player Stats"
      assert html =~ "Health:"
      assert html =~ "Stamina:"
      assert html =~ "Mana:"
    end

    test "renders control buttons", %{view: view} do
      html = render(view)
      assert html =~ "Character Sheet"
      assert html =~ "Inventory"
      assert html =~ "Quests"
      assert html =~ "Map"
      assert html =~ "Settings"
    end
  end

  describe "handle_event/3" do
    setup do
      user = 
        %Shard.Users.User{}
        |> Shard.Users.User.registration_changeset(%{
          email: "test3@example.com",
          password: "password123"
        })
        |> Repo.insert!()

      character_attrs = %{
        name: "Test Character",
        level: 1,
        experience: 0,
        user_id: user.id
      }

      {:ok, character} = Characters.create_character(character_attrs)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/play/#{@map_id}?character_id=#{character.id}&character_name=Test%20Character")

      %{
        view: view,
        character: character
      }
    end

    test "opens modal when control button is clicked", %{view: view} do
      # Test character sheet modal
      assert view |> element("button", "Character Sheet") |> render_click() =~ "Character Sheet Modal"
      
      # Close modal
      assert view |> element("#close-modal") |> render_click() =~ "MUD Game"
      
      # Test inventory modal
      assert view |> element("button", "Inventory") |> render_click() =~ "Inventory Modal"
      
      # Close modal
      assert view |> element("#close-modal") |> render_click() =~ "MUD Game"
      
      # Test quests modal
      assert view |> element("button", "Quests") |> render_click() =~ "Quests Modal"
      
      # Close modal
      assert view |> element("#close-modal") |> render_click() =~ "MUD Game"
    end

    test "handles movement keypress events", %{view: view} do
      # Test ArrowUp key
      html = render_hook(view, "keypress", %{"key" => "ArrowUp"})
      assert html =~ "You move north."

      # Test ArrowDown key
      html = render_hook(view, "keypress", %{"key" => "ArrowDown"})
      assert html =~ "You move south."

      # Test ArrowLeft key
      html = render_hook(view, "keypress", %{"key" => "ArrowLeft"})
      assert html =~ "You move west."

      # Test ArrowRight key
      html = render_hook(view, "keypress", %{"key" => "ArrowRight"})
      assert html =~ "You move east."

      # Test non-movement key (should not change anything)
      original_html = render(view)
      html = render_hook(view, "keypress", %{"key" => "Enter"})
      assert html == original_html
    end

    test "handles submit_command event", %{view: view} do
      # Test help command
      html = render_hook(view, "submit_command", %{"command" => %{"text" => "help"}})
      assert html =~ "> help"
      assert html =~ "Available commands:"

      # Test look command
      html = render_hook(view, "submit_command", %{"command" => %{"text" => "look"}})
      assert html =~ "> look"
      assert html =~ "You look around"

      # Test empty command
      original_html = render(view)
      html = render_hook(view, "submit_command", %{"command" => %{"text" => "   "}})
      assert html == original_html
    end

    test "handles update_command event", %{view: view} do
      html = render_hook(view, "update_command", %{"command" => %{"text" => "test command"}})
      assert html =~ "test command"
    end

    test "handles click_exit event", %{view: view} do
      # Test moving north
      html = render_hook(view, "click_exit", %{"dir" => "north"})
      assert html =~ "You move north."

      # Test moving south
      html = render_hook(view, "click_exit", %{"dir" => "south"})
      assert html =~ "You move south."

      # Test moving east
      html = render_hook(view, "click_exit", %{"dir" => "east"})
      assert html =~ "You move east."

      # Test moving west
      html = render_hook(view, "click_exit", %{"dir" => "west"})
      assert html =~ "You move west."
    end
  end

  describe "handle_info/2" do
    setup do
      user = 
        %Shard.Users.User{}
        |> Shard.Users.User.registration_changeset(%{
          email: "test4@example.com",
          password: "password123"
        })
        |> Repo.insert!()

      character_attrs = %{
        name: "Test Character",
        level: 1,
        experience: 0,
        user_id: user.id
      }

      {:ok, character} = Characters.create_character(character_attrs)

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/play/#{@map_id}?character_id=#{character.id}&character_name=Test%20Character")

      %{
        view: view,
        character: character
      }
    end

    test "handles noise messages", %{view: view} do
      html = render_hook(view, :noise, "A sound echoes through the dungeon...")
      assert html =~ "A sound echoes through the dungeon..."
    end

    test "handles area_heal messages", %{view: view} do
      # Initial health should be 100
      initial_html = render(view)
      assert initial_html =~ "Health: 100/100"
      
      # Reduce health first
      view |> render_hook(:area_heal, {5, "The healing fountain glows brightly!"})
      
      # Health should now be 100 (no change since it was already at max)
      html = render(view)
      assert html =~ "Health: 100/100"
    end
  end

  defp log_in_user(conn, user) do
    token = Shard.Users.generate_user_session_token(user)
    conn |> Plug.Test.init_test_session(%{}) |> Plug.Conn.put_session(:user_token, token)
  end
end
