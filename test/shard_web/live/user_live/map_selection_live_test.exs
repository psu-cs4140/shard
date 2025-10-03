defmodule ShardWeb.MapSelectionLiveTest do
  use ShardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures
  import Shard.CharactersFixtures

  describe "Map Selection page" do
    test "renders map selection page", %{conn: conn} do
      {:ok, _lv, html} =
        conn
        |> log_in_user(user_fixture())
        |> live(~p"/maps")

      assert html =~ "Choose Your Adventure"
      assert html =~ "Tutorial Terrain"
    end

    test "redirects if user is not logged in", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/maps")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/users/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end
  end

  describe "Character selection modal" do
    setup %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      %{conn: conn, user: user}
    end

    test "opens modal in create mode when user has no characters", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/maps")

      lv
      |> element("button[phx-click=select_map]", "Tutorial Terrain")
      |> render_click()

      html = render(lv)
      assert html =~ "Create New Character"
      assert html =~ "Create your first character"
    end

    test "opens modal in select mode when user has characters", %{conn: conn, user: user} do
      character_fixture(user: user)

      {:ok, lv, _html} = live(conn, ~p"/maps")

      lv
      |> element("button[phx-click=select_map]", "Tutorial Terrain")
      |> render_click()

      html = render(lv)
      assert html =~ "Choose Your Character"
      assert html =~ "Found 1 character"
    end

    test "switches between create and select modes", %{conn: conn, user: user} do
      character_fixture(user: user)

      {:ok, lv, _html} = live(conn, ~p"/maps")

      # Open modal
      lv
      |> element("button[phx-click=select_map]", "Tutorial Terrain")
      |> render_click()

      # Switch to create mode
      lv
      |> element("button", "Create New Character")
      |> render_click()

      assert render(lv) =~ "Character Name"

      # Switch back
      lv
      |> element("button[type=button]", "Back to Selection")
      |> render_click()

      html = render(lv)
      assert html =~ "Choose Your Character"
      refute html =~ "Character Name"
    end

    test "validates character creation form", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/maps")

      # Open modal and switch to create
      lv
      |> element("button[phx-click=select_map]", "Tutorial Terrain")
      |> render_click()

      # Submit empty form
      result =
        lv
        |> form("#character-form", %{character: %{}})
        |> render_submit()

      assert result =~ "can&#39;t be blank"
    end

    test "creates character and navigates to map", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/maps")

      # Open modal in create mode (no characters)
      lv
      |> element("button[phx-click=select_map]", "Tutorial Terrain")
      |> render_click()

      # Submit valid character data
      {:ok, conn, html} =
        lv
        |> form("#character-form", %{
          character: %{
            name: "Test Warrior",
            class: "warrior",
            race: "human"
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/maps")

      # Should redirect to play route with character params
      assert html =~ "tutorial_terrain"
      assert html =~ "Test%20Warrior"
    end

    test "selects existing character and navigates to map", %{conn: conn, user: user} do
      character = character_fixture(user: user)

      {:ok, lv, _html} = live(conn, ~p"/maps")

      # Open modal
      lv
      |> element("button[phx-click=select_map]", "Tutorial Terrain")
      |> render_click()

      # Select character
      {:ok, conn, html} =
        lv
        |> element("button[phx-value-character_id=#{character.id}]")
        |> render_click()
        |> follow_redirect(conn, ~p"/maps")

      # Should redirect to play route with character params
      assert html =~ "tutorial_terrain"
      assert html =~ URI.encode(character.name)
    end

    test "reloads characters when modal opens", %{conn: conn, user: user} do
      {:ok, lv, _html} = live(conn, ~p"/maps")

      # Open modal (should show create mode since no characters)
      lv
      |> element("button[phx-click=select_map]", "Tutorial Terrain")
      |> render_click()

      assert render(lv) =~ "Create your first character"

      # Simulate character being created elsewhere
      character_fixture(user: user)

      # Close and reopen modal - should reload and show selection mode
      lv
      |> element("button", "Cancel")
      |> render_click()
      |> element("button[phx-click=select_map]", "Tutorial Terrain")
      |> render_click()

      html = render(lv)
      assert html =~ "Found 1 character"
    end
  end
end
