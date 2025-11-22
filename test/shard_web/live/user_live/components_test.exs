defmodule ShardWeb.UserLive.ComponentsTest do
  use ShardWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shard.UsersFixtures
  import Shard.CharactersFixtures

  alias ShardWeb.UserLive.Components

  describe "character_sheet/1" do
    test "renders character sheet modal with character data" do
      user = user_fixture()
      character = character_fixture(user_id: user.id)

      assigns = %{
        character: character,
        show_character_sheet: true
      }

      html = render_component(&Components.character_sheet/1, assigns)

      assert html =~ "Character Sheet"
      assert html =~ character.name
      assert html =~ "Level #{character.level}"
      assert html =~ "Health: #{character.current_health}/#{character.max_health}"
      assert html =~ "Mana: #{character.current_mana}/#{character.max_mana}"
      assert html =~ "Experience: #{character.experience}/#{character.experience_to_next_level}"
    end

    test "does not render when show_character_sheet is false" do
      user = user_fixture()
      character = character_fixture(user_id: user.id)

      assigns = %{
        character: character,
        show_character_sheet: false
      }

      html = render_component(&Components.character_sheet/1, assigns)

      refute html =~ "Character Sheet"
    end

    test "renders stats section with character attributes" do
      user = user_fixture()
      character = character_fixture(user_id: user.id)

      assigns = %{
        character: character,
        show_character_sheet: true
      }

      html = render_component(&Components.character_sheet/1, assigns)

      assert html =~ "Strength: #{character.strength}"
      assert html =~ "Dexterity: #{character.dexterity}"
      assert html =~ "Constitution: #{character.constitution}"
      assert html =~ "Intelligence: #{character.intelligence}"
      assert html =~ "Wisdom: #{character.wisdom}"
      assert html =~ "Charisma: #{character.charisma}"
    end

    test "includes close button with phx-click event" do
      user = user_fixture()
      character = character_fixture(user_id: user.id)

      assigns = %{
        character: character,
        show_character_sheet: true
      }

      html = render_component(&Components.character_sheet/1, assigns)

      assert html =~ ~s(phx-click="hide_modal")
      assert html =~ "×"
    end
  end

  describe "inventory/1" do
    test "renders inventory modal when show_inventory is true" do
      assigns = %{
        show_inventory: true,
        inventory: [],
        equipped_items: %{}
      }

      html = render_component(&Components.inventory/1, assigns)

      assert html =~ "Inventory"
      assert html =~ "Equipment"
    end

    test "does not render when show_inventory is false" do
      assigns = %{
        show_inventory: false,
        inventory: [],
        equipped_items: %{}
      }

      html = render_component(&Components.inventory/1, assigns)

      refute html =~ "Inventory"
    end

    test "renders inventory items when present" do
      inventory_items = [
        %{id: 1, name: "Health Potion", quantity: 3, description: "Restores health"},
        %{id: 2, name: "Iron Sword", quantity: 1, description: "A sturdy weapon"}
      ]

      assigns = %{
        show_inventory: true,
        inventory: inventory_items,
        equipped_items: %{}
      }

      html = render_component(&Components.inventory/1, assigns)

      assert html =~ "Health Potion"
      assert html =~ "Iron Sword"
      assert html =~ "Quantity: 3"
      assert html =~ "Quantity: 1"
    end

    test "renders equipped items when present" do
      equipped_items = %{
        "weapon" => %{id: 1, name: "Steel Sword", description: "A sharp blade"},
        "armor" => %{id: 2, name: "Leather Armor", description: "Basic protection"}
      }

      assigns = %{
        show_inventory: true,
        inventory: [],
        equipped_items: equipped_items
      }

      html = render_component(&Components.inventory/1, assigns)

      assert html =~ "Steel Sword"
      assert html =~ "Leather Armor"
    end

    test "includes close button with phx-click event" do
      assigns = %{
        show_inventory: true,
        inventory: [],
        equipped_items: %{}
      }

      html = render_component(&Components.inventory/1, assigns)

      assert html =~ ~s(phx-click="hide_modal")
      assert html =~ "×"
    end
  end

  describe "quests/1" do
    test "renders quests modal when show_quests is true" do
      assigns = %{
        show_quests: true,
        active_quests: [],
        completed_quests: []
      }

      html = render_component(&Components.quests/1, assigns)

      assert html =~ "Quests"
      assert html =~ "Active Quests"
      assert html =~ "Completed Quests"
    end

    test "does not render when show_quests is false" do
      assigns = %{
        show_quests: false,
        active_quests: [],
        completed_quests: []
      }

      html = render_component(&Components.quests/1, assigns)

      refute html =~ "Quests"
    end

    test "renders active quests when present" do
      active_quests = [
        %{id: 1, name: "Find the Lost Artifact", description: "Search for the ancient relic", progress: "2/5 items found"},
        %{id: 2, name: "Defeat the Goblin King", description: "Eliminate the threat", progress: "In progress"}
      ]

      assigns = %{
        show_quests: true,
        active_quests: active_quests,
        completed_quests: []
      }

      html = render_component(&Components.quests/1, assigns)

      assert html =~ "Find the Lost Artifact"
      assert html =~ "Defeat the Goblin King"
      assert html =~ "2/5 items found"
      assert html =~ "In progress"
    end

    test "renders completed quests when present" do
      completed_quests = [
        %{id: 3, name: "Village Rescue", description: "Save the villagers", completed_at: "2023-01-01"},
        %{id: 4, name: "Herb Collection", description: "Gather healing herbs", completed_at: "2023-01-02"}
      ]

      assigns = %{
        show_quests: true,
        active_quests: [],
        completed_quests: completed_quests
      }

      html = render_component(&Components.quests/1, assigns)

      assert html =~ "Village Rescue"
      assert html =~ "Herb Collection"
    end

    test "includes close button with phx-click event" do
      assigns = %{
        show_quests: true,
        active_quests: [],
        completed_quests: []
      }

      html = render_component(&Components.quests/1, assigns)

      assert html =~ ~s(phx-click="hide_modal")
      assert html =~ "×"
    end
  end

  describe "settings/1" do
    test "renders settings modal when show_settings is true" do
      assigns = %{
        show_settings: true,
        user: %{email: "test@example.com", admin: false}
      }

      html = render_component(&Components.settings/1, assigns)

      assert html =~ "Settings"
      assert html =~ "Account Settings"
    end

    test "does not render when show_settings is false" do
      assigns = %{
        show_settings: false,
        user: %{email: "test@example.com", admin: false}
      }

      html = render_component(&Components.settings/1, assigns)

      refute html =~ "Settings"
    end

    test "renders user email in settings" do
      user = %{email: "user@example.com", admin: false}

      assigns = %{
        show_settings: true,
        user: user
      }

      html = render_component(&Components.settings/1, assigns)

      assert html =~ "user@example.com"
    end

    test "includes close button with phx-click event" do
      assigns = %{
        show_settings: true,
        user: %{email: "test@example.com", admin: false}
      }

      html = render_component(&Components.settings/1, assigns)

      assert html =~ ~s(phx-click="hide_modal")
      assert html =~ "×"
    end

    test "renders logout button" do
      assigns = %{
        show_settings: true,
        user: %{email: "test@example.com", admin: false}
      }

      html = render_component(&Components.settings/1, assigns)

      assert html =~ "Log out"
    end
  end
end
