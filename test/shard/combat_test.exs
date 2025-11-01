defmodule Shard.CombatTest do
  use Shard.DataCase

  alias Shard.Combat
  alias Shard.Combat.Engine

  describe "in_combat?/1" do
    test "returns false when combat is not set" do
      game_state = %{}
      refute Combat.in_combat?(game_state)
    end

    test "returns false when combat is false" do
      game_state = %{combat: false}
      refute Combat.in_combat?(game_state)
    end

    test "returns true when combat is true" do
      game_state = %{combat: true}
      assert Combat.in_combat?(game_state)
    end
  end

  describe "execute_action/2" do
    setup do
      game_state = %{
        player_position: {0, 0},
        player_stats: %{strength: 10},
        equipped_weapon: %{damage: 5},
        character: %{name: "TestPlayer"},
        monsters: []
      }

      %{game_state: game_state}
    end

    test "returns error message for unknown action", %{game_state: game_state} do
      {messages, updated_state} = Combat.execute_action(game_state, "unknown")
      assert messages == ["Unknown combat action."]
      assert updated_state == game_state
    end

    test "handles attack action with no monsters", %{game_state: game_state} do
      {messages, updated_state} = Combat.execute_action(game_state, "attack")
      assert messages == ["There are no monsters here to attack."]
      assert updated_state == game_state
    end

    test "handles flee action", %{game_state: game_state} do
      game_state = Map.put(game_state, :combat, true)
      {messages, updated_state} = Combat.execute_action(game_state, "flee")
      assert messages == ["You flee from combat!"]
      assert updated_state.combat == false
    end
  end

  describe "start_combat/1" do
    test "does nothing when no monsters at position" do
      game_state = %{
        player_position: {0, 0},
        monsters: [%{position: {1, 1}, is_alive: true}]
      }

      {messages, updated_state} = Combat.start_combat(game_state)
      assert messages == []
      assert updated_state == game_state
    end

    test "starts combat when monsters are present" do
      monster = %{
        position: {0, 0},
        is_alive: true,
        name: "Goblin",
        hp: 10,
        hp_max: 10
      }

      game_state = %{
        player_position: {0, 0},
        monsters: [monster],
        combat: false
      }

      {messages, updated_state} = Combat.start_combat(game_state)

      assert length(messages) > 0
      assert String.contains?(Enum.join(messages), "Combat begins!")
      assert String.contains?(Enum.join(messages), "Goblin")
      assert updated_state.combat == true
    end
  end

  describe "Engine.damage/2" do
    test "calculates damage with no variance" do
      cfg = %{base: 10, variance: 0}
      damage = Engine.damage(cfg, 0)
      assert damage == 10
    end

    test "calculates damage with armor reduction" do
      cfg = %{base: 10, variance: 0}
      damage = Engine.damage(cfg, 3)
      assert damage == 7
    end

    test "ensures minimum damage of 1" do
      cfg = %{base: 5, variance: 0}
      damage = Engine.damage(cfg, 10)
      assert damage == 1
    end

    test "applies variance correctly" do
      cfg = %{base: 10, variance: 4}
      # With variance 4, damage should be between 8 and 14 (before armor)
      damage = Engine.damage(cfg, 0)
      assert damage >= 8 and damage <= 14
    end
  end

  describe "Engine.step/1" do
    test "handles empty state" do
      state = %{combat: false, monsters: [], players: [], effects: [], events: []}
      {:ok, new_state, events} = Engine.step(state)
      assert new_state == state
      assert events == []
    end

    test "handles state with monsters and players" do
      monster = %{position: {0, 0}, hp: 10, is_alive: true}
      player = %{id: "player1", position: {0, 0}, hp: 10}

      state = %{
        monsters: [monster],
        players: [player],
        effects: [],
        events: [],
        combat: true,
        room_position: {0, 0}
      }

      {:ok, new_state, events} = Engine.step(state)

      # Should return the same state with no effects
      assert new_state.monsters == [monster]
      assert new_state.players == [player]
      assert events == []
    end
  end

  describe "Engine.add_player/2" do
    test "adds new player to combat" do
      state = %{players: []}
      player = %{id: "player1", name: "TestPlayer"}

      new_state = Engine.add_player(state, player)

      assert length(new_state.players) == 1
      assert hd(new_state.players).id == "player1"
    end

    test "doesn't add duplicate player" do
      player = %{id: "player1", name: "TestPlayer"}
      state = %{players: [player]}

      new_state = Engine.add_player(state, player)

      assert length(new_state.players) == 1
    end
  end

  describe "Engine.remove_player/2" do
    test "removes player from combat" do
      player1 = %{id: "player1", name: "TestPlayer1"}
      player2 = %{id: "player2", name: "TestPlayer2"}
      state = %{players: [player1, player2]}

      new_state = Engine.remove_player(state, "player1")

      assert length(new_state.players) == 1
      assert hd(new_state.players).id == "player2"
    end
  end

  describe "Engine.update_player/3" do
    test "updates player stats" do
      player = %{id: "player1", name: "TestPlayer", hp: 10}
      state = %{players: [player]}

      new_state = Engine.update_player(state, "player1", %{hp: 5, name: "UpdatedPlayer"})

      updated_player = hd(new_state.players)
      assert updated_player.hp == 5
      assert updated_player.name == "UpdatedPlayer"
    end
  end

  describe "private functions" do
    test "parse_damage handles integers" do
      # This tests the private parse_damage function indirectly through execute_action
      game_state = %{
        player_position: {0, 0},
        player_stats: %{strength: 10, health: 100},
        equipped_weapon: %{damage: 5},
        character: %{name: "TestPlayer"},
        combat: false,
        monsters: [
          %{position: {0, 0}, is_alive: true, name: "TestMonster", hp: 10, armor: 0}
        ]
      }

      {messages, _updated_state} = Combat.execute_action(game_state, "attack")

      # Should successfully attack without crashing on damage parsing
      assert length(messages) > 0
      assert String.contains?(Enum.join(messages), "You attack")
    end
  end
end
