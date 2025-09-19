defmodule ShardWeb.MapControllerTest do
  use ShardWeb.ConnCase, async: true

  test "GET /map returns rooms and exits arrays with expected shape", %{conn: conn} do
    conn = get(conn, ~p"/map")
    assert %{"rooms" => rooms, "exits" => exits} = json_response(conn, 200)

    assert is_list(rooms)
    assert is_list(exits)

    if rooms != [] do
      room = hd(rooms)
      assert Map.has_key?(room, "id")
      assert Map.has_key?(room, "name")
      assert Map.has_key?(room, "description")
      assert Map.has_key?(room, "x")
      assert Map.has_key?(room, "y")
      assert Map.has_key?(room, "slug")
    end

    if exits != [] do
      ex = hd(exits)
      assert Map.has_key?(ex, "id")
      assert Map.has_key?(ex, "dir")
      assert Map.has_key?(ex, "to")
      assert Map.has_key?(ex, "from")
    end
  end
end
