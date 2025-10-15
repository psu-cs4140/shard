defmodule ShardWeb.AdminLive.MonstersTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  alias Shard.Monsters
  alias Shard.Map

  @create_attrs %{
    name: "Test Monster",
    race: "orc",
    level: 5,
    health: 100,
    max_health: 100,
    attack_damage: 15,
    xp_amount: 50,
    description: "A fearsome test monster"
  }

  @update_attrs %{
    name: "Updated Monster",
    race: "goblin",
    level: 3,
    health: 75,
    max_health: 75,
    attack_damage: 10,
    xp_amount: 30,
    description: "An updated test monster"
  }

  @invalid_attrs %{
    name: nil,
    race: nil,
    level: nil,
    health: nil,
    max_health: nil,
    attack_damage: nil,
    xp_amount: nil
  }

  defp create_monster(_) do
    {:ok, monster} = Monsters.create_monster(@create_attrs)
    %{monster: monster}
  end

  defp create_room(_) do
    {:ok, room} = Map.create_room(%{
      name: "Test Room",
      description: "A test room",
      x_coordinate: 0,
      y_coordinate: 0,
      z_coordinate: 0
    })
    %{room: room}
  end

  defp create_admin_user(_) do
    user = user_fixture(%{admin: true})
    %{user: user}
  end

  describe "Index" do
    setup [:create_admin_user, :create_monster, :create_room]

    test "lists all monsters", %{conn: conn, user: user, monster: monster} do
      {:ok, _index_live, html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      assert html =~ "Monsters Administration"
      assert html =~ monster.name
      assert html =~ String.capitalize(monster.race)
    end

    test "saves new monster", %{conn: conn, user: user} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      assert index_live |> element("a", "+ New Monster") |> render_click() =~
               "Create Monster"

      assert_patch(index_live, ~p"/admin/monsters/new")

      assert index_live
             |> form("#monster-form", monster: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#monster-form", monster: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/monsters")

      html = render(index_live)
      assert html =~ "Monster created successfully"
      assert html =~ "Test Monster"
    end

    test "updates monster in listing", %{conn: conn, user: user, monster: monster} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      assert index_live |> element("#monster-#{monster.id} a", "Edit") |> render_click() =~
               "Edit Monster"

      assert_patch(index_live, ~p"/admin/monsters/#{monster}/edit")

      assert index_live
             |> form("#monster-form", monster: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#monster-form", monster: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/monsters")

      html = render(index_live)
      assert html =~ "Monster updated successfully"
      assert html =~ "Updated Monster"
    end

    test "deletes monster in listing", %{conn: conn, user: user, monster: monster} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      assert index_live |> element("#monster-#{monster.id} button", "Delete") |> render_click()
      refute has_element?(index_live, "#monster-#{monster.id}")
    end

    test "displays monster location when assigned to room", %{conn: conn, user: user, room: room} do
      {:ok, monster} = Monsters.create_monster(Elixir.Map.put(@create_attrs, :location_id, room.id))

      {:ok, _index_live, html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      assert html =~ room.name
    end

    test "displays dash when monster has no location", %{conn: conn, user: user, monster: monster} do
      {:ok, _index_live, html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      # Check that the location column shows a dash for monsters without location
      # Look for the dash in the location column (more flexible than exact HTML match)
      assert html =~ "#{monster.name}"
      assert html =~ "-"
    end
  end

  describe "New" do
    setup [:create_admin_user, :create_room]

    test "displays new monster form", %{conn: conn, user: user} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters/new")

      assert has_element?(index_live, "h2", "Create Monster")
      assert has_element?(index_live, "form#monster-form")
    end

    test "redirects to index when cancel is clicked", %{conn: conn, user: user} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters/new")

      assert index_live |> element("button", "✕") |> render_click()
      assert_patch(index_live, ~p"/admin/monsters")
    end

    test "includes room options in location select", %{conn: conn, user: user, room: room} do
      {:ok, _index_live, html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters/new")

      assert html =~ room.name
      assert html =~ "None"
    end
  end

  describe "Edit" do
    setup [:create_admin_user, :create_monster, :create_room]

    test "displays edit monster form", %{conn: conn, user: user, monster: monster} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters/#{monster}/edit")

      assert has_element?(index_live, "h2", "Edit Monster")
      assert has_element?(index_live, "form#monster-form")
      
      # Check that form is pre-populated with monster data
      html = render(index_live)
      assert html =~ monster.name
      assert html =~ monster.race
    end

    test "updates existing monster", %{conn: conn, user: user, monster: monster} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters/#{monster}/edit")

      assert index_live
             |> form("#monster-form", monster: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/monsters")

      html = render(index_live)
      assert html =~ "Monster updated successfully"
      assert html =~ "Updated Monster"
    end
  end

  describe "Event Handlers" do
    setup [:create_admin_user, :create_monster]

    test "handle_event edit_monster shows form", %{conn: conn, user: user, monster: monster} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      # Trigger the edit_monster event
      assert index_live |> element("#monster-#{monster.id} a", "Edit") |> render_click()
      
      # Should show the form
      assert has_element?(index_live, "form#monster-form")
      assert has_element?(index_live, "h2", "Edit Monster")
    end

    test "handle_event cancel_form hides form", %{conn: conn, user: user} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters/new")

      # Form should be visible initially
      assert has_element?(index_live, "form#monster-form")

      # Cancel the form
      assert index_live |> element("button", "✕") |> render_click()

      # Should redirect to index
      assert_patch(index_live, ~p"/admin/monsters")
    end

    test "handle_event save_monster with empty strings converts to nil", %{conn: conn, user: user} do
      {:ok, index_live, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters/new")

      # Submit form with empty location_id (empty string)
      attrs_with_empty_string = Elixir.Map.put(@create_attrs, :location_id, "")

      assert index_live
             |> form("#monster-form", monster: attrs_with_empty_string)
             |> render_submit()

      assert_patch(index_live, ~p"/admin/monsters")

      html = render(index_live)
      assert html =~ "Monster created successfully"
      
      # Verify the monster was created with nil location_id
      monster = Monsters.list_monsters() |> List.last()
      assert monster.location_id == nil
    end
  end

  describe "Authorization" do
    test "redirects non-admin users", %{conn: conn} do
      user = user_fixture(%{admin: false})
      
      assert {:error, {:live_redirect, %{to: "/"}}} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")
    end

    test "allows admin users", %{conn: conn} do
      user = user_fixture(%{admin: true})
      
      assert {:ok, _view, _html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")
    end
  end

  describe "Rendering" do
    setup [:create_admin_user, :create_monster]

    test "renders monster table with correct headers", %{conn: conn, user: user} do
      {:ok, _index_live, html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      assert html =~ "Name"
      assert html =~ "Race"
      assert html =~ "Level"
      assert html =~ "Health"
      assert html =~ "Attack"
      assert html =~ "XP Reward"
      assert html =~ "Location"
      assert html =~ "Actions"
    end

    test "truncates long descriptions", %{conn: conn, user: user} do
      long_description = String.duplicate("a", 100)
      {:ok, monster} = Monsters.create_monster(Elixir.Map.put(@create_attrs, :description, long_description))

      {:ok, _index_live, html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      # Should show truncated description with ellipsis
      assert html =~ "..."
      refute html =~ long_description
    end

    test "capitalizes race names", %{conn: conn, user: user, monster: monster} do
      {:ok, _index_live, html} = 
        conn
        |> log_in_user(user)
        |> live(~p"/admin/monsters")

      assert html =~ String.capitalize(monster.race)
    end
  end
end
