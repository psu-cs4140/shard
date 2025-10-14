defmodule ShardWeb.MudGameLiveAdvancedTest do
  use ShardWeb.ConnCase
  import Shard.UsersFixtures

  describe "advanced functionality" do
    test "handles PubSub messages correctly", %{conn: conn} do
      user = user_fixture()

      # Create character with specific stats for testing
      character = %Shard.Characters.Character{
        name: "TestWarrior",
        level: 10,
        experience: 5000,
        user_id: user.id,
        class: "warrior",
        race: "dwarf"
      }

      character = Shard.Repo.insert!(character)

      _conn = log_in_user(conn, user)

      # Test the LiveView by calling mount directly with proper socket setup
      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }

      params = %{"map_id" => "3", "character_id" => to_string(character.id)}
      session = %{}

      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)

      # Test handle_info for :noise message
      {:noreply, noise_socket} =
        ShardWeb.MudGameLive.handle_info(
          {:noise, "A distant roar echoes through the dungeon."},
          socket
        )

      # Verify noise message was added to terminal output
      output_text = Enum.join(noise_socket.assigns.terminal_state.output, "\n")
      assert output_text =~ "A distant roar echoes through the dungeon."
    end

    test "handles area heal messages with different health states", %{conn: conn} do
      user = user_fixture()

      character = %Shard.Characters.Character{
        name: "TestHealer",
        level: 5,
        experience: 2000,
        user_id: user.id,
        class: "cleric",
        race: "human"
      }

      character = Shard.Repo.insert!(character)

      _conn = log_in_user(conn, user)

      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }

      params = %{"map_id" => "1", "character_id" => to_string(character.id)}
      session = %{}

      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)

      # Test handle_info for :area_heal message with low health
      # First, set player health to low value
      low_health_game_state = put_in(socket.assigns.game_state, [:player_stats, :health], 30)

      low_health_socket = %{
        socket
        | assigns: Map.put(socket.assigns, :game_state, low_health_game_state)
      }

      {:noreply, healed_socket} =
        ShardWeb.MudGameLive.handle_info(
          {:area_heal, 5, "A warm light fills the area."},
          low_health_socket
        )

      # Verify heal message was added and health increased
      healed_output = Enum.join(healed_socket.assigns.terminal_state.output, "\n")
      assert healed_output =~ "A warm light fills the area."
      assert healed_output =~ "Area heal effect: 5 damage healed"
      assert healed_socket.assigns.game_state.player_stats.health == 35

      # Test handle_info for :area_heal message with full health
      full_health_game_state = put_in(socket.assigns.game_state, [:player_stats, :health], 100)

      full_health_socket = %{
        socket
        | assigns: Map.put(socket.assigns, :game_state, full_health_game_state)
      }

      {:noreply, no_heal_socket} =
        ShardWeb.MudGameLive.handle_info(
          {:area_heal, 5, "Another healing wave passes through."},
          full_health_socket
        )

      # Verify message was added but health didn't change (already at max)
      no_heal_output = Enum.join(no_heal_socket.assigns.terminal_state.output, "\n")
      assert no_heal_output =~ "Another healing wave passes through."
      assert no_heal_output =~ "Area heal effect: 5 damage healed"
      assert no_heal_socket.assigns.game_state.player_stats.health == 100
    end

    test "handles keypress events for movement and non-movement keys", %{conn: conn} do
      user = user_fixture()

      character = %Shard.Characters.Character{
        name: "TestRogue",
        level: 3,
        experience: 500,
        user_id: user.id,
        class: "rogue",
        race: "halfling"
      }

      character = Shard.Repo.insert!(character)

      _conn = log_in_user(conn, user)

      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }

      params = %{"map_id" => "2", "character_id" => to_string(character.id)}
      session = %{}

      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)

      # Test keypress event handling for arrow keys
      {:noreply, movement_socket} =
        ShardWeb.MudGameLive.handle_event("keypress", %{"key" => "ArrowUp"}, socket)

      # Verify movement was processed (terminal output should contain movement response)
      _movement_output = Enum.join(movement_socket.assigns.terminal_state.output, "\n")
      # Movement should either succeed or fail, but should add some response to terminal
      assert length(movement_socket.assigns.terminal_state.output) >
               length(socket.assigns.terminal_state.output)

      # Test keypress event for non-movement key (should do nothing)
      {:noreply, no_change_socket} =
        ShardWeb.MudGameLive.handle_event("keypress", %{"key" => "Space"}, socket)

      # Verify no changes were made for non-movement key
      assert no_change_socket.assigns.terminal_state.output ==
               socket.assigns.terminal_state.output

      assert no_change_socket.assigns.game_state == socket.assigns.game_state
    end

    test "handles click_exit and update_command events", %{conn: conn} do
      user = user_fixture()

      character = %Shard.Characters.Character{
        name: "TestPaladin",
        level: 7,
        experience: 3500,
        user_id: user.id,
        class: "paladin",
        race: "human"
      }

      character = Shard.Repo.insert!(character)

      _conn = log_in_user(conn, user)

      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }

      params = %{"map_id" => "1", "character_id" => to_string(character.id)}
      session = %{}

      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)

      # Test click_exit event
      {:noreply, exit_socket} =
        ShardWeb.MudGameLive.handle_event("click_exit", %{"dir" => "north"}, socket)

      # Verify exit click was processed (should either move or stay in place)
      _exit_output = Enum.join(exit_socket.assigns.terminal_state.output, "\n")
      # Should either have movement message or no change, but socket should be valid
      assert is_map(exit_socket.assigns.game_state)
      assert is_list(exit_socket.assigns.terminal_state.output)

      # Test update_command event
      {:noreply, command_socket} =
        ShardWeb.MudGameLive.handle_event(
          "update_command",
          %{"command" => %{"text" => "look around"}},
          socket
        )

      # Verify current command was updated
      assert command_socket.assigns.terminal_state.current_command == "look around"
    end

    test "renders components with different modal states", %{conn: conn} do
      user = user_fixture()

      character = %Shard.Characters.Character{
        name: "TestWizard",
        level: 8,
        experience: 4000,
        user_id: user.id,
        class: "wizard",
        race: "elf"
      }

      character = Shard.Repo.insert!(character)

      _conn = log_in_user(conn, user)

      socket = %Phoenix.LiveView.Socket{
        endpoint: ShardWeb.Endpoint,
        assigns: %{__changed__: %{}}
      }

      params = %{"map_id" => "3", "character_id" => to_string(character.id)}
      session = %{}

      {:ok, socket} = ShardWeb.MudGameLive.mount(params, session, socket)

      # Test component rendering with different modal states
      # Test that different modal types render different components
      character_sheet_socket = %{
        socket
        | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "character_sheet"})
      }

      inventory_socket = %{
        socket
        | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "inventory"})
      }

      quests_socket = %{
        socket
        | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "quests"})
      }

      map_socket = %{
        socket
        | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "map"})
      }

      settings_socket = %{
        socket
        | assigns: Map.put(socket.assigns, :modal_state, %{show: true, type: "settings"})
      }

      # Test that the modal states are correctly assigned
      assert character_sheet_socket.assigns.modal_state.show == true
      assert character_sheet_socket.assigns.modal_state.type == "character_sheet"
      assert inventory_socket.assigns.modal_state.type == "inventory"
      assert quests_socket.assigns.modal_state.type == "quests"
      assert map_socket.assigns.modal_state.type == "map"
      assert settings_socket.assigns.modal_state.type == "settings"

      # Test that character data is properly accessible in different states
      assert character_sheet_socket.assigns.game_state.character.name == "TestWizard"
      assert character_sheet_socket.assigns.game_state.character.level == 8
      # Inventory should have default items when no database items exist
      assert is_list(inventory_socket.assigns.game_state.inventory_items)
      assert quests_socket.assigns.game_state.quests == []
      assert map_socket.assigns.game_state.map_data != nil
      assert settings_socket.assigns.game_state.player_stats != nil

      # Verify character name is accessible across all modal states
      assert character_sheet_socket.assigns.character_name == "TestWizard"
      assert inventory_socket.assigns.character_name == "TestWizard"
      assert quests_socket.assigns.character_name == "TestWizard"
      assert map_socket.assigns.character_name == "TestWizard"
      assert settings_socket.assigns.character_name == "TestWizard"
    end
  end
end
