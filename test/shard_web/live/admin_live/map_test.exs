defmodule ShardWeb.AdminLive.MapTest do
  use ShardWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Shard.Map
  alias Shard.Map.{Room, Door}

  describe "Map LiveView" do
    setup do
      # Clean up any existing data
      Shard.Repo.delete_all(Door)
      Shard.Repo.delete_all(Room)

      # Create test rooms
      {:ok, room1} = Map.create_room(%{
        name: "Test Room 1",
        description: "A test room",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })

      {:ok, room2} = Map.create_room(%{
        name: "Test Room 2", 
        description: "Another test room",
        x_coordinate: 1,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "safe_zone",
        is_public: true
      })

      # Create test door
      {:ok, door} = Map.create_door(%{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "east",
        door_type: "standard",
        is_locked: false
      })

      %{room1: room1, room2: room2, door: door}
    end

    test "mounts successfully and displays rooms", %{conn: conn, room1: room1, room2: room2} do
      {:ok, view, html} = live(conn, ~p"/admin/map")

      assert html =~ "Map Management"
      assert html =~ room1.name
      assert html =~ room2.name
    end

    test "switches between tabs", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Switch to doors tab
      html = view |> element("button", "Doors") |> render_click()
      assert html =~ "New Door"

      # Switch to map visualization tab
      html = view |> element("button", "Map Visualization") |> render_click()
      assert html =~ "Map Visualization"
      assert html =~ "Zoom In"
    end

    test "creates new room", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Click new room button
      view |> element("button", "New Room") |> render_click()

      # Fill out the form
      view
      |> form("#room-form", room: %{
        name: "New Test Room",
        description: "A newly created room",
        x_coordinate: 2,
        y_coordinate: 0,
        z_coordinate: 0,
        room_type: "standard",
        is_public: true
      })
      |> render_submit()

      # Verify room was created
      rooms = Map.list_rooms()
      assert Enum.any?(rooms, &(&1.name == "New Test Room"))
    end

    test "edits existing room", %{conn: conn, room1: room1} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Click edit button for room1
      view |> element("button[phx-value-id='#{room1.id}']", "Edit") |> render_click()

      # Update the room
      view
      |> form("#room-form", room: %{
        name: "Updated Room Name",
        description: room1.description,
        x_coordinate: room1.x_coordinate,
        y_coordinate: room1.y_coordinate,
        z_coordinate: room1.z_coordinate,
        room_type: room1.room_type,
        is_public: room1.is_public
      })
      |> render_submit()

      # Verify room was updated
      updated_room = Map.get_room!(room1.id)
      assert updated_room.name == "Updated Room Name"
    end

    test "deletes room", %{conn: conn, room1: room1} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Delete the room
      view |> element("button[phx-value-id='#{room1.id}']", "Delete") |> render_click()

      # Verify room was deleted
      assert_raise Ecto.NoResultsError, fn ->
        Map.get_room!(room1.id)
      end
    end

    test "views room details", %{conn: conn, room1: room1} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Click view button
      html = view |> element("button[phx-value-id='#{room1.id}']", "View") |> render_click()

      assert html =~ "Room Details: #{room1.name}"
      assert html =~ "Apply and Save"
    end

    test "creates new door", %{conn: conn, room1: room1, room2: room2} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Switch to doors tab
      view |> element("button", "Doors") |> render_click()

      # Click new door button
      view |> element("button", "New Door") |> render_click()

      # Fill out the form
      view
      |> form("#door-form", door: %{
        from_room_id: room1.id,
        to_room_id: room2.id,
        direction: "west",
        door_type: "standard",
        is_locked: false
      })
      |> render_submit()

      # Verify door was created
      doors = Map.list_doors()
      assert Enum.any?(doors, &(&1.direction == "west" && &1.from_room_id == room1.id))
    end

    test "edits existing door", %{conn: conn, door: door} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Switch to doors tab
      view |> element("button", "Doors") |> render_click()

      # Click edit button for door
      view |> element("button[phx-value-id='#{door.id}']", "Edit") |> render_click()

      # Update the door
      view
      |> form("#door-form", door: %{
        from_room_id: door.from_room_id,
        to_room_id: door.to_room_id,
        direction: "west",
        door_type: "gate",
        is_locked: true
      })
      |> render_submit()

      # Verify door was updated
      updated_door = Map.get_door!(door.id)
      assert updated_door.direction == "west"
      assert updated_door.door_type == "gate"
      assert updated_door.is_locked == true
    end

    test "deletes door", %{conn: conn, door: door} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Switch to doors tab
      view |> element("button", "Doors") |> render_click()

      # Delete the door
      view |> element("button[phx-value-id='#{door.id}']", "Delete") |> render_click()

      # Verify door was deleted
      assert_raise Ecto.NoResultsError, fn ->
        Map.get_door!(door.id)
      end
    end

    test "generates default map", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Click generate default map
      html = view |> element("button", "Generate Default Map") |> render_click()

      assert html =~ "Default 3x3 map generated successfully!"

      # Verify 9 rooms were created (3x3 grid)
      rooms = Map.list_rooms()
      assert length(rooms) == 9

      # Verify center room is safe_zone
      center_room = Enum.find(rooms, &(&1.x_coordinate == 1 && &1.y_coordinate == 1))
      assert center_room.room_type == "safe_zone"
    end

    test "handles map zoom controls", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Switch to map tab
      view |> element("button", "Map Visualization") |> render_click()

      # Test zoom in
      view |> element("button", "Zoom In") |> render_click()
      
      # Test zoom out
      view |> element("button", "Zoom Out") |> render_click()
      
      # Test reset view
      view |> element("button", "Reset View") |> render_click()
    end

    test "validates room form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Click new room button
      view |> element("button", "New Room") |> render_click()

      # Submit form with invalid data (missing required name)
      html = view
      |> form("#room-form", room: %{
        name: "",
        description: "Test",
        x_coordinate: 0,
        y_coordinate: 0,
        z_coordinate: 0
      })
      |> render_change()

      # Form should show validation errors
      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
    end

    test "cancels room creation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Click new room button
      view |> element("button", "New Room") |> render_click()

      # Cancel the form
      view |> element("button", "Cancel") |> render_click()

      # Should return to rooms list without modal
      refute has_element?(view, "#room-modal")
    end

    test "cancels door creation", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Switch to doors tab and create new door
      view |> element("button", "Doors") |> render_click()
      view |> element("button", "New Door") |> render_click()

      # Cancel the form
      view |> element("button", "Cancel") |> render_click()

      # Should return to doors list without modal
      refute has_element?(view, "#door-modal")
    end

    test "generates AI description for room", %{conn: conn, room1: room1} do
      # Set up AI config to return dummy response
      Application.put_env(:shard, :open_router, [api_key: nil])

      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # View room details
      view |> element("button[phx-value-id='#{room1.id}']", "View") |> render_click()

      # Click generate description button
      html = view |> element("button", "✨ Generate with AI") |> render_click()

      # Should update the description field
      assert html =~ "A test room description generated without an API call."
    end

    test "applies and saves room changes", %{conn: conn, room1: room1} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # View room details
      view |> element("button[phx-value-id='#{room1.id}']", "View") |> render_click()

      # Update room details
      view
      |> form("#room-details-form", room: %{
        name: "Updated via Details",
        description: room1.description,
        x_coordinate: room1.x_coordinate,
        y_coordinate: room1.y_coordinate,
        z_coordinate: room1.z_coordinate,
        room_type: room1.room_type,
        is_public: room1.is_public
      })
      |> render_submit()

      # Verify room was updated
      updated_room = Map.get_room!(room1.id)
      assert updated_room.name == "Updated via Details"
    end

    test "navigates back to rooms from details", %{conn: conn, room1: room1} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # View room details
      view |> element("button[phx-value-id='#{room1.id}']", "View") |> render_click()

      # Click back to rooms
      html = view |> element("button", "Back to Rooms") |> render_click()

      # Should be back on rooms tab
      assert html =~ "New Room"
      refute html =~ "Room Details:"
    end

    test "handles mouse events for map dragging", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Switch to map tab
      view |> element("button", "Map Visualization") |> render_click()

      # Test mouse events
      view |> render_hook("mousedown", %{"clientX" => 100, "clientY" => 100})
      view |> render_hook("mousemove", %{"clientX" => 150, "clientY" => 150})
      view |> render_hook("mouseup", %{})
      view |> render_hook("mouseleave", %{})
    end

    test "handles form validation errors", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/map")

      # Try to create room with invalid data
      view |> element("button", "New Room") |> render_click()

      # Submit empty form
      html = view
      |> form("#room-form", room: %{})
      |> render_submit()

      # Should show validation errors and stay on form
      assert has_element?(view, "#room-modal")
    end
  end
end
