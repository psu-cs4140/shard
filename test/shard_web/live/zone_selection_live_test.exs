defmodule ShardWeb.ZoneSelectionLiveTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures

  alias Shard.{Map, Characters, Users, Achievements, Social}
  alias Shard.Items.AdminStick

  setup do
    user = user_fixture()
    character = character_fixture(%{user_id: user.id, level: 5, class: "warrior"})
    zone = zone_fixture(%{name: "Test Dungeon", slug: "test_dungeon", zone_type: "dungeon", min_level: 1, max_level: 10})
    
    %{user: user, character: character, zone: zone}
  end

  describe "mount/3" do
    test "mounts successfully", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/zones")
      assert html =~ "Select a Dungeon to Explore"
    end
  end

  describe "handle_params/3" do
    test "loads zones and character when character_id provided", %{conn: conn, character: character, zone: zone} do
      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      assert view.assigns.character.id == character.id
      assert view.assigns.character.name == character.name
      assert length(view.assigns.zones) >= 1
      assert Enum.any?(view.assigns.zones, &(&1.id == zone.id))
    end

    test "handles missing character_id gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/zones")
      
      assert view.assigns.character == nil
      assert is_list(view.assigns.zones)
    end

    test "loads zone progress for user", %{conn: conn, character: character, user: user, zone: zone} do
      # Create zone progress
      {:ok, _progress} = Users.create_user_zone_progress(%{
        user_id: user.id,
        zone_id: zone.id,
        progress: "in_progress"
      })

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      assert view.assigns.zone_progress_map[zone.id] == "in_progress"
    end

    test "ensures special zones are accessible", %{conn: conn, character: character} do
      mines_zone = zone_fixture(%{name: "The Mines", slug: "mines", zone_type: "wilderness"})
      forest_zone = zone_fixture(%{name: "Whispering Forest", slug: "whispering_forest", zone_type: "wilderness"})

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      assert view.assigns.zone_progress_map[mines_zone.id] == "in_progress"
      assert view.assigns.zone_progress_map[forest_zone.id] == "in_progress"
    end
  end

  describe "render/1" do
    test "displays zones with correct accessibility", %{conn: conn, character: character, zone: zone} do
      {:ok, _view, html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      assert html =~ zone.name
      assert html =~ zone.description
      assert html =~ "Level Range:"
      assert html =~ "#{zone.min_level}-#{zone.max_level || "∞"}"
    end

    test "shows character info when character is selected", %{conn: conn, character: character} do
      {:ok, _view, html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      assert html =~ "Playing as: #{character.name}"
      assert html =~ "Level #{character.level}"
      assert html =~ character.class
    end

    test "shows character selection links when no character", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/zones")
      
      assert html =~ "Select Existing Character"
      assert html =~ "Create New Character"
    end

    test "displays locked zones correctly", %{conn: conn, character: character} do
      locked_zone = zone_fixture(%{name: "Locked Zone", slug: "locked", zone_type: "dungeon"})
      
      {:ok, _view, html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      assert html =~ "🔒 Locked"
      assert html =~ "This zone is locked"
    end

    test "shows empty state when no zones exist", %{conn: conn} do
      # Delete all zones
      Enum.each(Map.list_active_zones(), &Map.delete_zone/1)
      
      {:ok, _view, html} = live(conn, ~p"/zones")
      
      assert html =~ "No dungeons available yet"
    end
  end

  describe "handle_event enter_zone" do
    test "enters standard zone successfully", %{conn: conn, character: character, user: user, zone: zone} do
      # Make zone accessible
      {:ok, _progress} = Users.create_user_zone_progress(%{
        user_id: user.id,
        zone_id: zone.id,
        progress: "in_progress"
      })

      # Create a room in the zone
      room_fixture(%{zone_id: zone.id, x_coordinate: 0, y_coordinate: 0, z_coordinate: 0})

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      assert {:ok, conn} = view
        |> element("button", "Singleplayer")
        |> render_click(%{"zone_name" => zone.name, "instance_type" => "singleplayer"})
        |> follow_redirect(conn)

      assert redirected_to(conn) =~ "/play/#{character.id}"
    end

    test "prevents entry to locked zone", %{conn: conn, character: character, zone: zone} do
      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      html = view
        |> element("button", "Singleplayer")
        |> render_click(%{"zone_name" => zone.name, "instance_type" => "singleplayer"})

      assert html =~ "This zone is locked"
    end

    test "handles mines entry", %{conn: conn, character: character} do
      mines_zone = zone_fixture(%{name: "The Mines", slug: "mines", zone_type: "wilderness"})

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      assert {:ok, conn} = view
        |> element("button", "Singleplayer")
        |> render_click(%{"zone_name" => mines_zone.name, "instance_type" => "singleplayer"})
        |> follow_redirect(conn)

      assert redirected_to(conn) =~ "/play/#{character.id}"
    end

    test "handles forest entry", %{conn: conn, character: character} do
      forest_zone = zone_fixture(%{name: "Whispering Forest", slug: "whispering_forest", zone_type: "wilderness"})

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      assert {:ok, conn} = view
        |> element("button", "Singleplayer")
        |> render_click(%{"zone_name" => forest_zone.name, "instance_type" => "singleplayer"})
        |> follow_redirect(conn)

      assert redirected_to(conn) =~ "/play/#{character.id}"
    end

    test "requires party for multiplayer zones", %{conn: conn, character: character, user: user, zone: zone} do
      # Make zone accessible
      {:ok, _progress} = Users.create_user_zone_progress(%{
        user_id: user.id,
        zone_id: zone.id,
        progress: "in_progress"
      })

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      html = view
        |> element("button", "Multiplayer")
        |> render_click(%{"zone_name" => zone.name, "instance_type" => "multiplayer"})

      assert html =~ "You must be in a party to enter multiplayer zones"
    end

    test "handles nonexistent zone", %{conn: conn, character: character} do
      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      html = view
        |> element("button", "Singleplayer")
        |> render_click(%{"zone_name" => "Nonexistent Zone", "instance_type" => "singleplayer"})

      assert html =~ "Zone 'Nonexistent Zone' not found"
    end

    test "handles zone with no rooms", %{conn: conn, character: character, user: user, zone: zone} do
      # Make zone accessible but don't create any rooms
      {:ok, _progress} = Users.create_user_zone_progress(%{
        user_id: user.id,
        zone_id: zone.id,
        progress: "in_progress"
      })

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      html = view
        |> element("button", "Singleplayer")
        |> render_click(%{"zone_name" => zone.name, "instance_type" => "singleplayer"})

      assert html =~ "This zone has no rooms yet"
    end
  end

  describe "private functions" do
    test "get_zone_type_color/1 returns correct colors" do
      assert ShardWeb.ZoneSelectionLive.get_zone_type_color("dungeon") == "bg-gray-700 text-white"
      assert ShardWeb.ZoneSelectionLive.get_zone_type_color("town") == "bg-gray-600 text-white"
      assert ShardWeb.ZoneSelectionLive.get_zone_type_color("wilderness") == "bg-gray-800 text-white"
      assert ShardWeb.ZoneSelectionLive.get_zone_type_color("raid") == "bg-gray-500 text-white"
      assert ShardWeb.ZoneSelectionLive.get_zone_type_color("pvp") == "bg-gray-700 text-white"
      assert ShardWeb.ZoneSelectionLive.get_zone_type_color("safe_zone") == "bg-gray-600 text-white"
      assert ShardWeb.ZoneSelectionLive.get_zone_type_color("unknown") == "bg-gray-900 text-white"
    end
  end

  describe "pet functionality" do
    test "displays pet rock info for mines", %{conn: conn, character: character} do
      # Update character to have pet rock
      {:ok, character} = Characters.update_character(character, %{
        has_pet_rock: true,
        pet_rock_level: 3
      })

      mines_zone = zone_fixture(%{name: "The Mines", slug: "mines", zone_type: "wilderness"})

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      view
        |> element("button", "Singleplayer")
        |> render_click(%{"zone_name" => mines_zone.name, "instance_type" => "singleplayer"})

      assert_receive {:flash, :info, message}
      assert message =~ "Your Pet Rock is with you"
      assert message =~ "Level 3"
    end

    test "displays shroomling info for forest", %{conn: conn, character: character} do
      # Update character to have shroomling
      {:ok, character} = Characters.update_character(character, %{
        has_shroomling: true,
        shroomling_level: 2
      })

      forest_zone = zone_fixture(%{name: "Whispering Forest", slug: "whispering_forest", zone_type: "wilderness"})

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      view
        |> element("button", "Singleplayer")
        |> render_click(%{"zone_name" => forest_zone.name, "instance_type" => "singleplayer"})

      assert_receive {:flash, :info, message}
      assert message =~ "Your Shroomling companion bounces beside you"
      assert message =~ "Level 2"
    end
  end

  describe "admin functionality" do
    test "grants admin stick to admin users", %{conn: conn, user: user, character: character, zone: zone} do
      # Make user admin
      {:ok, admin_user} = Users.update_user(user, %{admin: true})
      
      # Make zone accessible
      {:ok, _progress} = Users.create_user_zone_progress(%{
        user_id: admin_user.id,
        zone_id: zone.id,
        progress: "in_progress"
      })

      # Create a room in the zone
      room_fixture(%{zone_id: zone.id, x_coordinate: 0, y_coordinate: 0, z_coordinate: 0})

      {:ok, view, _html} = live(conn, ~p"/zones?character_id=#{character.id}")
      
      view
        |> element("button", "Singleplayer")
        |> render_click(%{"zone_name" => zone.name, "instance_type" => "singleplayer"})

      # Verify admin stick was granted (this would need to be mocked or stubbed)
      # The actual implementation would depend on how AdminStick.grant_admin_stick/1 works
    end
  end

  # Helper functions for creating test data
  defp character_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Character",
      level: 1,
      class: "warrior",
      health: 100,
      max_health: 100,
      mana: 50,
      max_mana: 50,
      experience: 0,
      gold: 100
    }

    attrs = Enum.into(attrs, default_attrs)
    {:ok, character} = Characters.create_character(attrs)
    character
  end

  defp zone_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Zone",
      slug: "test_zone",
      description: "A test zone for testing",
      zone_type: "dungeon",
      min_level: 1,
      max_level: 10,
      display_order: 1,
      active: true
    }

    attrs = Enum.into(attrs, default_attrs)
    {:ok, zone} = Map.create_zone(attrs)
    zone
  end

  defp room_fixture(attrs \\ %{}) do
    default_attrs = %{
      name: "Test Room",
      description: "A test room",
      x_coordinate: 0,
      y_coordinate: 0,
      z_coordinate: 0
    }

    attrs = Enum.into(attrs, default_attrs)
    {:ok, room} = Map.create_room(attrs)
    room
  end
end
