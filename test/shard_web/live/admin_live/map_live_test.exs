defmodule ShardWeb.AdminLive.MapLiveTest do
  use ShardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Shard.Map

  describe "map management page" do
    setup [:register_and_log_in_user]

    test "displays rooms and doors tabs", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/admin/map")

      assert html =~ "Map Management"
      assert html =~ "Rooms"
      assert html =~ "Doors"
      assert html =~ "Map Visualization"
    end

    test "can switch between tabs", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Initially on rooms tab
      assert has_element?(view, "#rooms-tab")

      # Switch to doors tab
      view |> element("button[phx-value-tab=doors]") |> render_click()
      assert has_element?(view, "#doors-tab")

      # Switch to map visualization tab
      view |> element("button[phx-value-tab=map]") |> render_click()
      assert has_element?(view, "#map-visualization-tab")
    end

    test "can create a new room", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Click new room button
      view |> element("button[phx-click=new_room]") |> render_click()

      # Fill in room form
      view
      |> form("#room-form", room: %{
        name: "Test Room",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })
      |> render_submit()

      # Check that room was created
      assert render(view) =~ "Room created successfully"
      assert render(view) =~ "Test Room"
    end

    test "can create a new door", %{conn: conn} do
      # First create two rooms
      {:ok, room1} = Map.create_room(%{
        name: "Room 1",
        description: "First room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Map.create_room(%{
        name: "Room 2",
        description: "Second room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Switch to doors tab
      view |> element("button[phx-value-tab=doors]") |> render_click()

      # Click new door button
      view |> element("button[phx-click=new_door]") |> render_click()

      # Fill in door form
      view
      |> form("#door-form", door: %{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })
      |> render_submit()

      # Check that door was created
      assert render(view) =~ "Door created successfully"
      assert render(view) =~ "Room 1"
      assert render(view) =~ "Room 2"
      assert render(view) =~ "east"
    end

    test "can generate default map", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Click generate default map button
      view |> element("button[phx-click=generate_default_map]") |> render_click()

      # Check that default map was generated
      assert render(view) =~ "Default 3x3 map generated successfully!"
      assert render(view) =~ "Room 0,0"
      assert render(view) =~ "Room 1,1"
      assert render(view) =~ "Room 2,2"
    end
  end
end
