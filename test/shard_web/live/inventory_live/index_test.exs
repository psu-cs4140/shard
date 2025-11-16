defmodule ShardWeb.InventoryLive.IndexTest do
  use ShardWeb.ConnCase

  import Phoenix.LiveViewTest
  import Shard.AccountsFixtures
  import Shard.CharactersFixtures
  import Shard.ItemsFixtures
  import Shard.MapFixtures

  alias Shard.{Characters, Items, Map}

  describe "Index" do
    setup do
      user = user_fixture()
      character = character_fixture(%{user_id: user.id})
      zone = zone_fixture()
      room = room_fixture(%{zone_id: zone.id, x_coordinate: 0, y_coordinate: 0})
      
      # Update character location
      Characters.update_character(character, %{location: "{0,0}", current_zone_id: zone.id})

      %{user: user, character: character, zone: zone, room: room}
    end

    test "renders inventory page", %{conn: conn, user: user} do
      {:ok, _index_live, html} = live(conn |> log_in_user(user), ~p"/inventory")

      assert html =~ "Inventory"
    end

    test "displays character selection", %{conn: conn, user: user, character: character} do
      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      assert has_element?(index_live, "select[name='character_id']")
      assert has_element?(index_live, "option[value='#{character.id}']")
    end

    test "loads character inventory on mount", %{conn: conn, user: user, character: character} do
      item = item_fixture()
      inventory_item = character_inventory_fixture(%{character_id: character.id, item_id: item.id})

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      assert has_element?(index_live, "[data-inventory-id='#{inventory_item.id}']")
    end

    test "switches character when selected", %{conn: conn, user: user} do
      character1 = character_fixture(%{user_id: user.id, name: "Character 1"})
      character2 = character_fixture(%{user_id: user.id, name: "Character 2"})

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      index_live
      |> form("form", %{character_id: character2.id})
      |> render_change()

      # Verify the character was switched by checking if the form reflects the new selection
      assert has_element?(index_live, "option[value='#{character2.id}'][selected]")
    end

    test "picks up room item", %{conn: conn, user: user, character: character, room: room} do
      item = item_fixture()
      room_item = room_item_fixture(%{item_id: item.id, location: character.location, quantity: 1})

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      index_live
      |> element("[data-room-item-id='#{room_item.id}'] button", "Pick Up")
      |> render_click()

      assert_patch(index_live, ~p"/inventory")
      assert render(index_live) =~ "Item picked up successfully"
    end

    test "drops inventory item", %{conn: conn, user: user, character: character} do
      item = item_fixture()
      inventory_item = character_inventory_fixture(%{character_id: character.id, item_id: item.id})

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      index_live
      |> element("[data-inventory-id='#{inventory_item.id}'] button", "Drop")
      |> render_click()

      assert_patch(index_live, ~p"/inventory")
      assert render(index_live) =~ "Item dropped successfully"
    end

    test "equips item", %{conn: conn, user: user, character: character} do
      item = item_fixture(%{equippable: true, equipment_slot: "weapon"})
      inventory_item = character_inventory_fixture(%{character_id: character.id, item_id: item.id})

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      index_live
      |> element("[data-inventory-id='#{inventory_item.id}'] button", "Equip")
      |> render_click()

      assert_patch(index_live, ~p"/inventory")
      assert render(index_live) =~ "Item equipped successfully"
    end

    test "unequips item", %{conn: conn, user: user, character: character} do
      item = item_fixture(%{equippable: true, equipment_slot: "weapon"})
      inventory_item = character_inventory_fixture(%{
        character_id: character.id, 
        item_id: item.id, 
        equipped: true,
        equipment_slot: "weapon"
      })

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      index_live
      |> element("[data-inventory-id='#{inventory_item.id}'] button", "Unequip")
      |> render_click()

      assert_patch(index_live, ~p"/inventory")
      assert render(index_live) =~ "Item unequipped successfully"
    end

    test "sets hotbar slot", %{conn: conn, user: user, character: character} do
      item = item_fixture()
      inventory_item = character_inventory_fixture(%{character_id: character.id, item_id: item.id})

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      index_live
      |> element("[data-inventory-id='#{inventory_item.id}'] button", "Set Hotbar")
      |> render_click(%{slot: "1"})

      assert_patch(index_live, ~p"/inventory")
      assert render(index_live) =~ "Hotbar slot set successfully"
    end

    test "clears hotbar slot", %{conn: conn, user: user, character: character} do
      item = item_fixture()
      inventory_item = character_inventory_fixture(%{character_id: character.id, item_id: item.id})
      hotbar_slot = hotbar_slot_fixture(%{
        character_id: character.id, 
        slot_number: 1, 
        item_id: item.id,
        inventory_id: inventory_item.id
      })

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      index_live
      |> element("[data-hotbar-slot='1'] button", "Clear")
      |> render_click()

      assert_patch(index_live, ~p"/inventory")
      assert render(index_live) =~ "Hotbar slot cleared"
    end

    test "handles errors when picking up item fails", %{conn: conn, user: user, character: character} do
      # Create a room item that doesn't exist
      non_existent_room_item_id = 99999

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      index_live
      |> element("button[phx-click='pick_up_item'][phx-value-room_item_id='#{non_existent_room_item_id}']")
      |> render_click()

      assert render(index_live) =~ "Failed to pick up item"
    end

    test "handles errors when equipping non-equippable item", %{conn: conn, user: user, character: character} do
      item = item_fixture(%{equippable: false})
      inventory_item = character_inventory_fixture(%{character_id: character.id, item_id: item.id})

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      index_live
      |> element("[data-inventory-id='#{inventory_item.id}'] button", "Equip")
      |> render_click()

      assert render(index_live) =~ "Failed to equip item"
    end

    test "displays room items", %{conn: conn, user: user, character: character} do
      item = item_fixture(%{name: "Test Room Item"})
      room_item = room_item_fixture(%{item_id: item.id, location: character.location})

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      assert render(index_live) =~ "Test Room Item"
      assert has_element?(index_live, "[data-room-item-id='#{room_item.id}']")
    end

    test "displays hotbar items", %{conn: conn, user: user, character: character} do
      item = item_fixture(%{name: "Hotbar Item"})
      inventory_item = character_inventory_fixture(%{character_id: character.id, item_id: item.id})
      hotbar_slot = hotbar_slot_fixture(%{
        character_id: character.id,
        slot_number: 1,
        item_id: item.id,
        inventory_id: inventory_item.id
      })

      {:ok, index_live, _html} = live(conn |> log_in_user(user), ~p"/inventory")

      assert render(index_live) =~ "Hotbar Item"
      assert has_element?(index_live, "[data-hotbar-slot='1']")
    end
  end
end
