defmodule ShardWeb.AdminLive.MapComponentsTest do
  use ShardWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias ShardWeb.AdminLive.MapComponents

  describe "rooms_tab/1" do
    test "renders rooms table with rooms data" do
      rooms = [
        %Shard.Map.Room{
          id: 1,
          name: "Test Room",
          description: "A test room",
          x_coordinate: 0,
          y_coordinate: 0,
          z_coordinate: 0,
          room_type: "standard",
          is_public: true,
          properties: %{}
        }
      ]

      assigns = %{rooms: rooms}

      html = render_component(&MapComponents.rooms_tab/1, assigns)

      assert html =~ "Test Room"
      assert html =~ "0, 0, 0"
      assert html =~ "standard"
      assert html =~ "Yes"
      assert html =~ "New Room"
    end

    test "renders empty state when no rooms" do
      assigns = %{rooms: []}

      html = render_component(&MapComponents.rooms_tab/1, assigns)

      assert html =~ "No rooms found."
      assert html =~ "New Room"
    end
  end
end
